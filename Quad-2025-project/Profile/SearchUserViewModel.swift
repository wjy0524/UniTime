//
//  SearchUserViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import Foundation
import FirebaseFirestore

@MainActor
class SearchUserViewModel: ObservableObject {

    @Published var query: String = ""
    @Published var results: [QuadUser] = []

    private let db = Firestore.firestore()

    func search() async {
        let text = query.lowercased()

        guard !text.isEmpty else {
            results = []
            return
        }

        do {
            let snap = try await db.collection("users")
                .whereField("username_lower", isGreaterThanOrEqualTo: text)
                .whereField("username_lower", isLessThanOrEqualTo: text + "~")
                .getDocuments()

            self.results = snap.documents.compactMap {
                try? $0.data(as: QuadUser.self)
            }

        } catch {
            print("❌ Search error:", error)
        }
    }
}
