//
//  FollowListViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/7/26.
//

import FirebaseFirestore
import SwiftUI

@MainActor
class FollowListViewModel: ObservableObject {
    @Published var users: [QuadUser] = []

    private let db = Firestore.firestore()

    func fetch(uid: String, type: FollowListType) async {
        let field = (type == .followers) ? "followers" : "following"

        do {
            let snapshot = try await db
                .collection("users")
                .document(uid)
                .collection(field)
                .getDocuments()

            let ids = snapshot.documents.map { $0.documentID }

            guard !ids.isEmpty else {
                users = []
                return
            }

            let userSnap = try await db
                .collection("users")
                .whereField("uid", in: ids)
                .getDocuments()

            self.users = userSnap.documents.compactMap {
                try? $0.data(as: QuadUser.self)
            }

        } catch {
            print("❌ Follow list fetch error:", error)
        }
    }
}
