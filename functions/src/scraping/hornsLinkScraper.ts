//
//  utEventsScraper.ts
//  Quad-2025-project
//
//  Created by Isaac Choi on 1/12/26.
//

import * as functions from "firebase-functions";
import OpenAI from "openai";

interface UTEvent {
  title: string;
  content: string;
  category: string;
}

// Fetch events from UT Calendar API
async function fetchUTEvents(): Promise<UTEvent[]> {
  try {
    console.log("Fetching from UT Calendar API...");
    
    const response = await fetch("https://calendar.utexas.edu/api/2/events?pp=100");
    
    if (!response.ok) {
      console.error("API response not ok:", response.status);
      return [];
    }

    const data = await response.json();
    const events: UTEvent[] = [];

    for (const item of data.events || []) {
      const e = item.event;
      
      const title = e.title || "";
      const date = e.event_instances?.[0]?.event_instance?.start || "";
      const location = e.location_name || e.location || "";
      const description = e.description_text || "";
      
      if (title) {
        events.push({
          title: `UT Event: ${title}`,
          content: `Date: ${date}. ${location ? `Location: ${location}. ` : ""}${description}`.slice(0, 500),
          category: "events"
        });
      }
    }

    console.log(`Fetched ${events.length} events`);
    return events;

  } catch (error) {
    console.error("Fetch error:", error);
    return [];
  }
}

// Get embedding
async function getEmbedding(text: string, openai: OpenAI): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: "text-embedding-3-small",
    input: text,
  });
  return response.data[0].embedding;
}

// Upload events to Qdrant
async function uploadEvents(
  events: UTEvent[],
  qdrantUrl: string,
  qdrantKey: string,
  openai: OpenAI
) {
  let successCount = 0;

  for (let i = 0; i < events.length; i++) {
    const event = events[i];
    try {
      const vector = await getEmbedding(`${event.title} ${event.content}`, openai);
      
      const response = await fetch(`${qdrantUrl}/collections/utdata/points`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "api-key": qdrantKey,
        },
        body: JSON.stringify({
          points: [
            {
              id: Date.now() + i,
              vector: vector,
              payload: event,
            },
          ],
        }),
      });

      if (response.ok) {
        successCount++;
        console.log(`Uploaded: ${event.title.slice(0, 50)}...`);
      } else {
        console.error(`Upload failed: ${response.status}`);
      }

      // Rate limiting
      await new Promise(resolve => setTimeout(resolve, 200));
    } catch (error) {
      console.error(`Failed: ${event.title}`, error);
    }
  }

  return successCount;
}

/* ======================================================
   🔹 Scheduled Function - Runs daily at 6 AM CT
====================================================== */
export const scrapeEventsDaily = functions
  .runWith({ memory: "512MB", timeoutSeconds: 300 })
  .pubsub
  .schedule("0 6 * * *")
  .timeZone("America/Chicago")
  .onRun(async (context) => {
    const openaiKey = functions.config().openai?.key;
    const qdrantUrl = functions.config().qdrant?.url;
    const qdrantKey = functions.config().qdrant?.key;

    if (!openaiKey || !qdrantUrl || !qdrantKey) {
      console.error("Missing config keys");
      return null;
    }

    const openai = new OpenAI({ apiKey: openaiKey });

    try {
      console.log("=== Starting Daily Event Fetch ===");
      
      const events = await fetchUTEvents();
      if (events.length === 0) {
        console.log("No events found");
        return null;
      }

      const uploaded = await uploadEvents(events, qdrantUrl, qdrantKey, openai);
      
      console.log(`=== Complete: ${uploaded}/${events.length} events uploaded ===`);
      return null;

    } catch (error) {
      console.error("Fetch failed:", error);
      return null;
    }
  });

/* ======================================================
   🔹 Manual Trigger (for testing)
====================================================== */
export const scrapeEventsManual = functions
  .runWith({ memory: "512MB", timeoutSeconds: 300 })
  .https
  .onRequest(async (req, res) => {
    const openaiKey = functions.config().openai?.key;
    const qdrantUrl = functions.config().qdrant?.url;
    const qdrantKey = functions.config().qdrant?.key;

    if (!openaiKey || !qdrantUrl || !qdrantKey) {
      res.status(500).send("Missing config keys");
      return;
    }

    const openai = new OpenAI({ apiKey: openaiKey });

    try {
      const events = await fetchUTEvents();
      const uploaded = await uploadEvents(events, qdrantUrl, qdrantKey, openai);
      
      res.send(`Fetched and uploaded ${uploaded} events from calendar.utexas.edu!`);
    } catch (error) {
      console.error(error);
      res.status(500).send(`Error: ${error}`);
    }
  });
