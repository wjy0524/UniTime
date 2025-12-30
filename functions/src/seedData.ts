//
//  seedData.ts
//  Quad-2025-project
//
//  Created by Isaac Choi on 12/21/25.
//

import * as dotenv from "dotenv";
import * as fs from "fs";
import * as path from "path";

dotenv.config();

const WEAVIATE_URL = process.env.WEAVIATE_URL!;
const WEAVIATE_KEY = process.env.WEAVIATE_KEY!;
const OPENAI_KEY = process.env.OPENAI_API_KEY!;

interface DataItem {
  title: string;
  content: string;
  category: string;
}

// Load all JSON files from a directory
function loadJsonFiles(dirPath: string): DataItem[] {
  const items: DataItem[] = [];
  
  if (!fs.existsSync(dirPath)) {
    console.log(`Directory not found: ${dirPath}`);
    return items;
  }

  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    
    if (entry.isDirectory()) {
      // Recursively load from subdirectories
      items.push(...loadJsonFiles(fullPath));
    } else if (entry.name.endsWith(".json")) {
      try {
        const fileContent = fs.readFileSync(fullPath, "utf-8");
        const data = JSON.parse(fileContent);
        
        if (Array.isArray(data)) {
          items.push(...data);
          console.log(`Loaded ${data.length} items from ${fullPath}`);
        }
      } catch (error) {
        console.error(`Error loading ${fullPath}:`, error);
      }
    }
  }
  
  return items;
}

async function deleteExistingSchema() {
  try {
    const response = await fetch(`${WEAVIATE_URL}/v1/schema/UTData`, {
      method: "DELETE",
      headers: {
        "Authorization": `Bearer ${WEAVIATE_KEY}`,
      },
    });
    if (response.ok) {
      console.log("Existing schema deleted");
    }
  } catch (error) {
    console.log("No existing schema to delete");
  }
}

async function createSchema() {
  const response = await fetch(`${WEAVIATE_URL}/v1/schema`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${WEAVIATE_KEY}`,
    },
    body: JSON.stringify({
      class: "UTData",
      vectorizer: "none",
      properties: [
        { name: "title", dataType: ["text"] },
        { name: "content", dataType: ["text"] },
        { name: "category", dataType: ["text"] },
      ],
    }),
  });
  
  const result = await response.json();
  console.log("Schema created:", result);
}

async function getEmbedding(text: string): Promise<number[]> {
  const response = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${OPENAI_KEY}`,
    },
    body: JSON.stringify({
      model: "text-embedding-3-small",
      input: text,
    }),
  });
  const data = await response.json();
  return data.data[0].embedding;
}

async function addData(items: DataItem[]) {
  let successCount = 0;
  let errorCount = 0;

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    
    try {
      // Rate limiting - small delay between requests
      if (i > 0 && i % 10 === 0) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }

      const vector = await getEmbedding(`${item.title} ${item.content}`);
      
      const response = await fetch(`${WEAVIATE_URL}/v1/objects`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${WEAVIATE_KEY}`,
        },
        body: JSON.stringify({
          class: "UTData",
          properties: item,
          vector: vector,
        }),
      });

      if (response.ok) {
        successCount++;
        console.log(`[${i + 1}/${items.length}] Added: ${item.title}`);
      } else {
        errorCount++;
        const errorText = await response.text();
        console.error(`[${i + 1}/${items.length}] Failed: ${item.title} - ${errorText}`);
      }
    } catch (error) {
      errorCount++;
      console.error(`[${i + 1}/${items.length}] Error: ${item.title}`, error);
    }
  }

  return { successCount, errorCount };
}

async function main() {
  console.log("=== UT Data Seeder ===\n");

  // Validate environment variables
  if (!WEAVIATE_URL || !WEAVIATE_KEY || !OPENAI_KEY) {
    console.error("Missing environment variables. Check your .env file.");
    console.log("Required: WEAVIATE_URL, WEAVIATE_KEY, OPENAI_API_KEY");
    process.exit(1);
  }

  // Load all data from the data directory
  const dataDir = path.join(__dirname, "data");
  console.log(`Loading data from: ${dataDir}\n`);
  
  const allItems = loadJsonFiles(dataDir);
  
  if (allItems.length === 0) {
    console.error("No data found! Make sure JSON files are in src/data/");
    process.exit(1);
  }

  console.log(`\nTotal items to upload: ${allItems.length}\n`);

  // Delete existing schema and recreate
  console.log("Resetting schema...");
  await deleteExistingSchema();
  await new Promise(resolve => setTimeout(resolve, 2000)); // Wait for deletion
  await createSchema();

  // Upload all data
  console.log("\nUploading data to Weaviate...\n");
  const { successCount, errorCount } = await addData(allItems);

  console.log("\n=== Complete ===");
  console.log(`Success: ${successCount}`);
  console.log(`Errors: ${errorCount}`);
  console.log(`Total: ${allItems.length}`);
}

main().catch(console.error);
