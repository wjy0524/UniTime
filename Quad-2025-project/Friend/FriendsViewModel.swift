//
//  FriendsViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/30/26.
//

import FirebaseFirestore
import FirebaseAuth
import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {

    @Published var friends: [String] = []
    @Published var isLoading = true

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    let uid: String
    var myUid: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    init(uid: String) {
        self.uid = uid
        startListener()
    }

    func startListener() {
        listener?.remove()

        listener = db
            .collection("users")
            .document(uid)
            .collection("friends")
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }

                if let error {
                    print("❌ friends list listener error:", error)
                    return
                }

                self.friends = snap?.documents.map {
                    $0.documentID
                } ?? []

                self.isLoading = false
            }
    }

    deinit {
        listener?.remove()
        print("🧹 FriendsViewModel deinit")
    }
}
