import * as functions from "firebase-functions";
import OpenAI from "openai";

export const chat = functions.https.onCall(async (data, context) => {
  const message = data.message;

  if (!message) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Message is required"
    );
  }

  const apiKey = functions.config().openai?.key;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "OpenAI API key not configured"
    );
  }

  const client = new OpenAI({ apiKey });

  try {
    const response = await client.responses.create({
      model: "gpt-4.1-mini",
      input: message,
    });

    return {
      reply: response.output_text,
    };
  } catch (error) {
    console.error("OpenAI error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to get AI response"
    );
  }
});

