//
//  CourseChatViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.


import FirebaseFirestore
import FirebaseAuth
import Foundation

@MainActor
class CourseChatViewModel: ObservableObject {

    @Published var messages: [CourseMessage] = []
    @Published var messageText = ""
    @Published var currentUsername: String = ""

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var uid: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    func loadUsername() async {
        guard !uid.isEmpty else { return }

        do {
            let snapshot = try await db.collection("users")
                .document(uid)
                .getDocument()

            if let name = snapshot.data()?["username"] as? String {
                currentUsername = name
            }
        } catch {
            print("❌ Failed to load username:", error)
        }
    }


    // MARK: - Listen

    func startListening(courseId: String) {
        listener?.remove()

        listener = db.collection("courseChats")
            .document(courseId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("❌ Message listener error:", error)
                    return
                }

                guard let docs = snapshot?.documents else { return }

                self?.messages = docs.compactMap {
                    try? $0.data(as: CourseMessage.self)
                }
            }
    }

    // MARK: - Send Message

    func sendMessage(courseId: String) async {

        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let message = CourseMessage(
            senderId: uid,
            senderName: currentUsername.isEmpty ? "Unknown" : currentUsername,
            text: messageText,
            timestamp: Date()
        )

        do {
            // 1️⃣ 메시지 저장
            try db.collection("courseChats")
                .document(courseId)
                .collection("messages")
                .addDocument(from: message)

            // 2️⃣ 채팅방 메타 업데이트
            try await db.collection("courseChats")
                .document(courseId)
                .updateData([
                    "lastMessage": messageText,
                    "lastMessageTime": FieldValue.serverTimestamp(),
                    "lastSenderId": uid,       
                    "lastSenderName": currentUsername
                ])

            messageText = ""
            await markAsRead(courseId: courseId)

        } catch {
            print("❌ Send message error:", error)
        }
    }

    // MARK: - Read Status

    func markAsRead(courseId: String) async {
        guard !uid.isEmpty else { return }

        do {
            try await db.collection("courseChats")
                .document(courseId)
                .collection("readStatus")
                .document(uid)
                .setData([
                    "lastReadAt": FieldValue.serverTimestamp()
                ], merge: true)
        } catch {
            print("❌ markAsRead error:", error)
        }
    }

    deinit {
        listener?.remove()
    }
}
