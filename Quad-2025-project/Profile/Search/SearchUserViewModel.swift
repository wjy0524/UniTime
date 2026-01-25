//
//  SearchUserViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import FirebaseFirestore
import Foundation

@MainActor
class SearchUserViewModel: ObservableObject {

    @Published var query: String = ""
    @Published var results: [QuadUser] = []
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("users")
                .whereField("username_lower", isGreaterThanOrEqualTo: trimmed.lowercased())
                .whereField("username_lower", isLessThanOrEqualTo: trimmed.lowercased() + "\u{f8ff}")
                .limit(to: 20)
                .getDocuments()

            results = snapshot.documents.compactMap {
                try? $0.data(as: QuadUser.self)
            }

        } catch {
            print("❌ User search error:", error)
            results = []
        }
    }
}

