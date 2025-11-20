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
        guard !query.isEmpty else {
            results = []
            return
        }

        let keyword = query.lowercased()

        do {
            // 제목 검색
            let snap = try await db.collection("posts")
                .whereField("title", isGreaterThanOrEqualTo: keyword)
                .whereField("title", isLessThanOrEqualTo: keyword + "~")
                .getDocuments()

            results = snap.documents.compactMap { try? $0.data(as: Post.self) }
        } catch {
            print("Search error:", error)
        }
    }
}
