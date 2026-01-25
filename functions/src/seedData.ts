//
//  seedData.ts
//  Quad-2025-project
//
//  Created by Isaac Choi on 12/21/25.
//

import { QdrantClient } from "@qdrant/js-client-rest";
import OpenAI from "openai";
import * as fs from "fs";
import * as path from "path";
import * as dotenv from "dotenv";

dotenv.config();

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const qdrant = new QdrantClient({
  url: process.env.QDRANT_URL,
  apiKey: process.env.QDRANT_KEY,
});

const COLLECTION_NAME = "utdata";

interface DataItem {
  title: string;
  content: string;
  category: string;
}

// Get embedding from OpenAI
async function getEmbedding(text: string): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: "text-embedding-3-small",
    input: text,
  });
  return response.data[0].embedding;
}

// Load all JSON files from a directory recursively
function loadJsonFiles(dir: string): DataItem[] {
  const items: DataItem[] = [];
  
  if (!fs.existsSync(dir)) {
    console.log(`Directory not found: ${dir}`);
    return items;
  }

  function readDir(currentDir: string) {
    const files = fs.readdirSync(currentDir);
    
    for (const file of files) {
      const filePath = path.join(currentDir, file);
      const stat = fs.statSync(filePath);
      
      if (stat.isDirectory()) {
        readDir(filePath);
      } else if (file.endsWith(".json")) {
        try {
          const content = fs.readFileSync(filePath, "utf-8");
          const data = JSON.parse(content);
          if (Array.isArray(data)) {
            items.push(...data);
            console.log(`Loaded ${data.length} items from ${filePath}`);
          }
        } catch (err) {
          console.error(`Error loading ${filePath}:`, err);
        }
      }
    }
  }
  
  readDir(dir);
  return items;
}

async function main() {
  console.log("=== Starting Qdrant Seed ===\n");

  // Validate environment variables
  if (!process.env.QDRANT_URL || !process.env.QDRANT_KEY || !process.env.OPENAI_API_KEY) {
    console.error("Missing environment variables. Check your .env file.");
    console.log("Required: QDRANT_URL, QDRANT_KEY, OPENAI_API_KEY");
    process.exit(1);
  }

  // 1. Create collection (delete if exists)
  try {
    await qdrant.deleteCollection(COLLECTION_NAME);
    console.log("Deleted existing collection");
  } catch (e) {
    console.log("No existing collection to delete");
  }

  await qdrant.createCollection(COLLECTION_NAME, {
    vectors: {
      size: 1536, // OpenAI embedding size
      distance: "Cosine",
    },
  });
  console.log("Created collection:", COLLECTION_NAME);

  // 2. Load all data
  const dataDir = path.join(__dirname, "data");
  console.log(`\nLoading data from: ${dataDir}`);
  const items = loadJsonFiles(dataDir);
  
  if (items.length === 0) {
    console.error("No data found! Make sure JSON files are in src/data/");
    process.exit(1);
  }
  
  console.log(`\nTotal items to upload: ${items.length}\n`);

  // 3. Upload items
  let successCount = 0;

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const text = `${item.title} ${item.content}`;
    
    try {
      const vector = await getEmbedding(text);
      
      await qdrant.upsert(COLLECTION_NAME, {
        points: [
          {
            id: i + 1,
            vector: vector,
            payload: {
              title: item.title,
              content: item.content,
              category: item.category,
            },
          },
        ],
      });
      
      successCount++;
      console.log(`[${i + 1}/${items.length}] Added: ${item.title.slice(0, 50)}...`);
      
      // Rate limiting
      await new Promise((resolve) => setTimeout(resolve, 100));
    } catch (err) {
      console.error(`[${i + 1}/${items.length}] Failed: ${item.title}`, err);
    }
  }

  console.log(`\n=== Complete: ${successCount}/${items.length} items uploaded ===`);
}

main().catch(console.error);
