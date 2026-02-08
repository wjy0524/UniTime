import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import OpenAI from "openai";
import { serpSearch } from "./web/serpApi";
import { defineSecret } from 'firebase-functions/params';

// Define secrets
const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');
const QDRANT_API_KEY = defineSecret('QDRANT_API_KEY');
const QDRANT_URL = defineSecret('QDRANT_URL');

admin.initializeApp();
const db = admin.firestore();

// Add this line at the top with other exports
export { scrapeEventsDaily, scrapeEventsManual } from "./scraping/hornsLinkScraper";
export { gradeCalPredict } from "./GradeCal/GradeCalPredict";

/* ======================================================
   🔹 Intent Classifier (rule-based, fast)
====================================================== */
function classifyIntent(message: string): string[] {
  const text = message.toLowerCase();
  const intents: string[] = [];

  if (/(career|job|intern)/i.test(text)) intents.push("career");
  if (/(major|ece|cs|computer|engineering)/i.test(text)) intents.push("major");
  if (/(graduate|graduation|year|class year)/i.test(text)) intents.push("year");
  if (/(gpa|grade)/i.test(text)) intents.push("gpa");

  if (/(class|classes|course|schedule|semester)/i.test(text)) {
    intents.push("schedule");
    intents.push("major");
    intents.push("year");
  }

  return [...new Set(intents)];
}

/* ======================================================
   🔹 Build user context ONLY when relevant
====================================================== */
function buildUserContext(user: any, intents: string[]): string {
  let context = "";

  if (intents.includes("major") && user.major) {
    context += `- Major: ${user.major}\n`;
  }
  if (intents.includes("year") && user.year) {
    context += `- Academic Year: ${user.year}\n`;
  }
  if (intents.includes("gpa") && user.gpa) {
    context += `- GPA: ${user.gpa}\n`;
  }
  if (intents.includes("schedule") && user.scheduleSummary) {
    context += `- Current Schedule: ${user.scheduleSummary}\n`;
  }

  return context.trim();
}

/* ======================================================
   🔹 Cloud Function: chat
====================================================== */
export const chat = functions
  .runWith({
    secrets: ['OPENAI_API_KEY', 'QDRANT_API_KEY', 'QDRANT_URL']
  })
  .https.onCall(async (data, context) => {
    const { message } = data;
    const uid = context.auth?.uid;

    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "Login required");
    }
    if (!message) {
      throw new functions.https.HttpsError("invalid-argument", "Message required");
    }

    // Access secrets
    const openaiKey = OPENAI_API_KEY.value();
    const qdrantUrl = QDRANT_URL.value();
    const qdrantKey = QDRANT_API_KEY.value();

    if (!openaiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "OpenAI key missing"
      );
    }

    const openai = new OpenAI({ apiKey: openaiKey });

    try {
      /* --------------------------------------------------
         1️⃣ Intent detection
      -------------------------------------------------- */
      const intents = classifyIntent(message);

      /* --------------------------------------------------
         2️⃣ Load user profile (selective)
      -------------------------------------------------- */
      let userContext = "";
      const userSnap = await db.collection("users").doc(uid).get();

      if (userSnap.exists) {
        userContext = buildUserContext(userSnap.data(), intents);
      }

      const hasUserContext = Boolean(userContext);

      /* --------------------------------------------------
         3️⃣ Create embedding
      -------------------------------------------------- */
      const embedding = await openai.embeddings.create({
        model: "text-embedding-3-small",
        input: message,
      });

      const queryVector = embedding.data[0].embedding;

      /* --------------------------------------------------
         4️⃣ RAG with Qdrant (confidence-aware)
      -------------------------------------------------- */
      let retrievalContext = "";
      let hasGoodUniversityContext = false;

      if (qdrantUrl && qdrantKey) {
        try {
          const searchResponse = await fetch(`${qdrantUrl}/collections/utdata/points/search`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "api-key": qdrantKey,
            },
            body: JSON.stringify({
              vector: queryVector,
              limit: 5,
              with_payload: true,
              with_vector: false,
              score_threshold: 0.5,
            }),
          });

          if (searchResponse.ok) {
            const searchResult = await searchResponse.json();
            const results = searchResult.result || [];
            
            // 👇 ADD THIS LOGGING
            console.log("=== QDRANT DEBUG ===");
            console.log("Total results:", results.length);
            results.forEach((r: any, i: number) => {
              console.log(`Result ${i + 1}: score=${r.score.toFixed(3)}, title="${r.payload?.title}"`);
            });
            console.log("====================");

            // Check confidence: need 2+ results with max score >= 0.75
            let maxScore = 0;
            if (results.length > 0) {
              maxScore = Math.max(...results.map((r: any) => r.score || 0));
            }

            const QDRANT_THRESHOLD = 0.75;
            hasGoodUniversityContext = results.length >= 2 && maxScore >= QDRANT_THRESHOLD;

            if (hasGoodUniversityContext) {
              retrievalContext = results
                .map((r: any) => `- ${r.payload.title}: ${r.payload.content}`)
                .join("\n");
            }

            console.log(`Qdrant: ${results.length} results, maxScore: ${maxScore}, good: ${hasGoodUniversityContext}`);
          }
        } catch (err) {
          console.error("Qdrant search failed:", err);
        }
      }

      /* --------------------------------------------------
         5️⃣ SerpAPI fallback (when Qdrant insufficient)
      -------------------------------------------------- */
      let webContext = "";
      let usedWebSearch = false;

      if (!hasGoodUniversityContext) {
        console.log("🔎 Falling back to SerpAPI...");
        webContext = await serpSearch(message);
        usedWebSearch = Boolean(webContext);
        console.log(`SerpAPI: ${usedWebSearch ? "found results" : "no results"}`);
      }

      /* --------------------------------------------------
         6️⃣ Reasoning mode router
      -------------------------------------------------- */
      const reasoningMode = hasUserContext
        ? "PERSONAL"
        : hasGoodUniversityContext
        ? "CAMPUS"
        : usedWebSearch
        ? "WEB"
        : "GENERAL";

      console.log(`Mode: ${reasoningMode}`);

      /* --------------------------------------------------
         7️⃣ Generate answer
      -------------------------------------------------- */
      const completion = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: `
You are an intelligent AI advisor for University of Texas at Austin students. You're like a knowledgeable upperclassman who knows more about UT.

CRITICAL RULE:
If no reliable campus data or web data is provided, you MUST say:
"I don't have enough reliable information to answer that right now."

CRITICAL INSTRUCTIONS:
1. THINK about what the student actually wants to know, not just what they literally asked
2. Use the provided UT data as CONTEXT to inform your answer, not as your complete answer
3. REASON and give personalized ADVICE, not just facts
4. Combine UT data with your general knowledge when helpful
5. Be conversational and helpful, like a friend who knows UT well

Examples of good responses:
- User asks "What's CS 331?" → Don't just list prerequisites. Explain what it's about, how hard it is, and tips for success.
- User asks "Should I take 15 hours?" → Consider their major, year, and give real advice about workload.
- User asks "What events are happening?" → Highlight interesting ones, not just list them.

Current mode: ${reasoningMode}
- PERSONAL: You have verified info about this specific student. Use it to personalize advice.
- CAMPUS: You have official UT data. Use it as context to give informed answers.
- WEB: You have web search results. Use ONLY these results, do NOT guess or use prior knowledge.
- GENERAL: No specific data available. Use your general knowledge about UT and college life.

${hasUserContext ? `
STUDENT PROFILE (use to personalize your advice):
${userContext}
` : ""}

${hasGoodUniversityContext ? `
UT AUSTIN DATA (use as context, not as your complete answer):
${retrievalContext}
` : ""}

${usedWebSearch ? `
WEB SEARCH RESULTS (AUTHORITATIVE):
${webContext}

CRITICAL RULES FOR WEB MODE:
- Use ONLY the web search results above
- Do NOT use prior knowledge
- Do NOT guess
- If the answer is not in these results, say "I don't have enough information yet"
` : ""}

Remember: Students want ADVICE and INSIGHT, not Wikipedia entries. Be helpful, specific, and conversational.
          `,
          },
          {
            role: "user",
            content: message,
          },
        ],
      });

      return {
        reply: completion.choices[0].message.content,
      };
    } catch (err) {
      console.error("Chat error:", err);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate response"
      );
    }
  });
