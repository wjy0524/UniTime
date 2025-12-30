import * as functions from "firebase-functions";
import OpenAI from "openai";

export const chat = functions.https.onCall(async (data, context) => {
  const { message } = data;

  if (!message) {
    throw new functions.https.HttpsError("invalid-argument", "Message is required");
  }

  const openaiKey = functions.config().openai?.key;
  const weaviateUrl = functions.config().weaviate?.url;
  const weaviateKey = functions.config().weaviate?.key;

  if (!openaiKey) {
    throw new functions.https.HttpsError("failed-precondition", "OpenAI API key not configured");
  }

  const openai = new OpenAI({ apiKey: openaiKey });

  try {
    // 1️⃣ Create embedding
    const embedding = await openai.embeddings.create({
      model: "text-embedding-3-small",
      input: message,
    });
    const queryVector = embedding.data[0].embedding;

    // 2️⃣ Query Weaviate
    let contextText = "";

    if (weaviateUrl && weaviateKey) {
      const weaviateResponse = await fetch(`${weaviateUrl}/v1/graphql`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${weaviateKey}`,
        },
        body: JSON.stringify({
          query: `{
            Get {
              UTData(
                nearVector: { vector: ${JSON.stringify(queryVector)} }
                limit: 5
              ) {
                title
                content
                category
              }
            }
          }`,
        }),
      });

      const json = await weaviateResponse.json();
      const results = json?.data?.Get?.UTData ?? [];

      if (results.length > 0) {
        contextText = "Relevant UT information:\n" +
          results.map((r: any) => `- ${r.title}: ${r.content}`).join("\n");
      }
    }

    // 3️⃣ Generate answer
    const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `You are a helpful assistant for UT Austin students. Help them with courses, clubs, and campus life.
          
${contextText || "No specific data available - answer based on general knowledge."}`,
        },
        {
          role: "user",
          content: message,
        },
      ],
    });

    return {
      reply: response.choices[0].message.content,
    };
  } catch (err) {
    console.error("Chat error:", err);
    throw new functions.https.HttpsError("internal", "Failed to get AI response");
  }
});
