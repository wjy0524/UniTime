//
//  SearchPostsViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import Foundation
import FirebaseFirestore

@MainActor
class SearchPostsViewModel: ObservableObject {

    @Published var query = ""
    @Published var results: [Post] = []

    let db = Firestore.firestore()

    func search() async {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            results = []
            return
        }

        do {
            let snap = try await db.collection("posts")
                .whereField("keywords", arrayContains: q)
                .limit(to: 30)
                .getDocuments()

            results = snap.documents.compactMap { try? $0.data(as: Post.self) }
        } catch {
            print("❌ Search error:", error)
        }
    }
}
