//
//  newEmptyTypes.ts
//  Quad-2025-project
//
//  Created by Isaac Choi on 1/12/26.
//

export interface HornsLinkEvent {
  title: string;
  date: string;
  time: string;
  location: string;
  organization: string;
  description: string;
  category: string;
}

export interface WeaviateEvent {
  title: string;
  content: string;
  category: string;
}
