import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import OpenAI from "openai";

admin.initializeApp();
const db = admin.firestore();

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
export const chat = functions.https.onCall(async (data, context) => {
  const { message } = data;
  const uid = context.auth?.uid;

  if (!uid) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }
  if (!message) {
    throw new functions.https.HttpsError("invalid-argument", "Message required");
  }

  const openaiKey = functions.config().openai?.key;
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
       4️⃣ Optional RAG (Weaviate)
    -------------------------------------------------- */
    let retrievalContext = "";
    const weaviateUrl = functions.config().weaviate?.url;
    const weaviateKey = functions.config().weaviate?.key;

    if (weaviateUrl && weaviateKey) {
      try {
        const res = await fetch(`${weaviateUrl}/v1/graphql`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${weaviateKey}`,
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
                }
              }
            }`,
          }),
        });

        if (res.ok) {
          const json = await res.json();
          const results = json?.data?.Get?.UTData ?? [];

          if (results.length > 0) {
            retrievalContext =
              results.map((r: any) => `- ${r.title}: ${r.content}`).join("\n");
          }
        }
      } catch (err) {
        console.error("Weaviate failed:", err);
      }
    }

    const hasUniversityContext = Boolean(retrievalContext);

    /* --------------------------------------------------
       5️⃣ Reasoning mode router
    -------------------------------------------------- */
    const reasoningMode = hasUserContext
      ? "PERSONAL"
      : hasUniversityContext
      ? "CAMPUS"
      : "GENERAL";

    /* --------------------------------------------------
       6️⃣ Generate answer
    -------------------------------------------------- */
    const completion = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "system",
          content: `
You are an AI assistant for a University of Texas at Austin student.

Current reasoning mode: ${reasoningMode}

Rules:
- PERSONAL: Use verified user profile data directly.
- CAMPUS: Use official UT Austin academic data.
- GENERAL: Answer exactly like a standard ChatGPT model.

General mode behavior:
- Use general knowledge freely.
- Answer confidently and clearly.
- Do NOT say "check official website" unless uncertainty is unavoidable.
- For dates and facts, give the most widely accepted answer.
- If uncertain, clearly state it is an estimate.

${hasUserContext ? `Verified user profile:\n${userContext}` : ""}

${hasUniversityContext ? `Official UT Austin data:\n${retrievalContext}` : ""}
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

