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
    @Published var unreadCounts: [String: Int] = [:]

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var uid: String? {
        Auth.auth().currentUser?.uid
    }

    func startListening() {

        guard let uid = uid else { return }

        listener?.remove()

        listener = db.collection("courseChats")
            .whereField("members", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("❌ CourseChat listener error:", error)
                    return
                }

                guard let docs = snapshot?.documents else { return }

                let chats = docs.compactMap {
                    try? $0.data(as: CourseChat.self)
                }

                self?.chats = chats.sorted {
                    ($0.lastMessageTime ?? Date.distantPast) >
                    ($1.lastMessageTime ?? Date.distantPast)
                }

                // 🔥 unread 계산
                for chat in chats {
                    if let id = chat.id {
                        self?.calculateUnread(for: id)
                    }
                }
            }
    }
    
    private func calculateUnread(for chatId: String) {

        guard let uid = uid else { return }

        let readRef = db.collection("courseChats")
            .document(chatId)
            .collection("readStatus")
            .document(uid)

        readRef.getDocument { [weak self] snapshot, _ in

            let lastReadAt = snapshot?.data()?["lastReadAt"] as? Timestamp
            let lastReadDate = lastReadAt?.dateValue()

            let messagesRef = self?.db.collection("courseChats")
                .document(chatId)
                .collection("messages")

            var query: Query = messagesRef!

            if let lastReadDate {
                query = query.whereField("timestamp", isGreaterThan: lastReadDate)
            }

            query.getDocuments { snapshot, _ in
                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self?.unreadCounts[chatId] = count
                }
            }
        }
    }

    deinit {
        listener?.remove()
    }
}
