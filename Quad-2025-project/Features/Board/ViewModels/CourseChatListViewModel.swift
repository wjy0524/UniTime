//
//  CourseChatListViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import FirebaseFirestore
import FirebaseAuth
import Foundation

@MainActor
class CourseChatListViewModel: ObservableObject {
    @Published var chats: [CourseChat] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var uid: String { Auth.auth().currentUser?.uid ?? "" }

    func startListening() {
        listener?.remove()

        listener = db.collection("courseChats")
            .whereField("members", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self?.chats = docs.compactMap { try? $0.data(as: CourseChat.self) }
            }
    }

    deinit {
        listener?.remove()
    }
}
