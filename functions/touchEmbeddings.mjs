//
//  touchEmbeddings.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 12/21/25.
//

import OpenAI from "openai";
import fetch from "node-fetch";
import "dotenv/config";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const embedding = await openai.embeddings.create({
  model: "text-embedding-3-small",
  input: "What CS classes cover computer security?",
});

const vector = embedding.data[0].embedding;

const res = await fetch(`${process.env.WEAVIATE_URL}/v1/graphql`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${process.env.WEAVIATE_KEY}`,
  },
  body: JSON.stringify({
    query: `
    {
      Get {
        UTData(
          nearVector: { vector: ${JSON.stringify(vector)} }
          limit: 3
        ) {
          title
          category
        }
      }
    }
    `,
  }),
});

console.log(JSON.stringify(await res.json(), null, 2));
