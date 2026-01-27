//
//  serpAPI.ts
//  Quad-2025-project
//
//  Created by Isaac Choi on 1/26/26.
//

import fetch from "node-fetch";
import * as functions from "firebase-functions";

const SERP_API_KEY = functions.config().serpapi?.key;

export async function serpSearch(query: string): Promise<string> {
  if (!SERP_API_KEY) {
    console.warn("SerpAPI key missing");
    return "";
  }

  const url = `https://serpapi.com/search.json?q=${encodeURIComponent(
    query
  )}&engine=google&num=5&api_key=${SERP_API_KEY}`;

  try {
    const res = await fetch(url);
    if (!res.ok) return "";

    const data = await res.json();

    if (!data.organic_results || data.organic_results.length === 0) {
      return "";
    }

    return data.organic_results
      .slice(0, 5)
      .map(
        (r: any, i: number) =>
          `Source ${i + 1}: ${r.title}\n${r.snippet}`
      )
      .join("\n\n");
  } catch (err) {
    console.error("SerpAPI error:", err);
    return "";
  }
}
