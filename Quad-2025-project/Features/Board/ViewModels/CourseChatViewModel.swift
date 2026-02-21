//
//  CourseChatViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import FirebaseFirestore
import FirebaseAuth
import Foundation

@MainActor
class CourseChatViewModel: ObservableObject {

    @Published var messages: [CourseMessage] = []
    @Published var messageText = ""

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var uid: String { Auth.auth().currentUser?.uid ?? "" }

    func startListening(courseId: String) {
        listener?.remove()

        listener = db.collection("courseChats")
            .document(courseId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self?.messages = docs.compactMap {
                    try? $0.data(as: CourseMessage.self)
                }
            }
    }

    func sendMessage(courseId: String) async {
        guard !messageText.isEmpty else { return }

        let message = CourseMessage(
            senderId: uid,
            text: messageText,
            timestamp: Date()
        )

        try? db.collection("courseChats")
            .document(courseId)
            .collection("messages")
            .addDocument(from: message)

        messageText = ""
    }

    deinit {
        listener?.remove()
    }
}
