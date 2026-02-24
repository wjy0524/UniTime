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
    @Published var userCache: [String: QuadUser] = [:]
    @Published var replyingTo: CourseMessage? = nil

    @Published var typingUsers: [String: (username: String, updatedAt: Date)] = [:]
    @Published var readStatusMap: [String: Int] = [:]

    // ✅ 추가
    @Published var isLoadingMore: Bool = false

    private let db = Firestore.firestore()

    private var listener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?

    private let pageSize = 30
    private var isFetchingMore = false

    private var typingListener: ListenerRegistration?
    private var typingRefreshTimer: Timer?

    private var readStatusListener: ListenerRegistration?

    var uid: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    func loadUsername() async {
        guard !uid.isEmpty else { return }
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let name = snapshot.data()?["username"] as? String {
                currentUsername = name
            }
        } catch {
            print("❌ Failed to load username:", error)
        }
    }

    func startReadStatusListener(courseId: String) {
        readStatusListener?.remove()

        readStatusListener = db.collection("courseChats")
            .document(courseId)
            .collection("readStatus")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                guard let docs = snapshot?.documents else { return }

                var map: [String: Int] = [:]
                for doc in docs {
                    let uid = doc.documentID
                    let lastRead = doc.data()["lastReadIndex"] as? Int ?? 0
                    map[uid] = lastRead
                }
                self.readStatusMap = map
            }
    }

    func startListening(courseId: String) {
        listener?.remove()

        let query = db.collection("courseChats")
            .document(courseId)
            .collection("messages")
            .order(by: "messageIndex", descending: true)
            .limit(to: pageSize)

        listener = query.addSnapshotListener { [weak self] snapshot, _ in
            guard let self else { return }
            guard let docs = snapshot?.documents else { return }

            self.lastDocument = docs.last

            let fetched = docs.compactMap { try? $0.data(as: CourseMessage.self) }
            let reversed = fetched.reversed()

            self.messages = Array(reversed)

            // sender preload
            let senderIds = Set(reversed.map { $0.senderId })
            Task {
                for id in senderIds {
                    await self.loadUser(uid: id)
                }
            }
        }
    }

    func loadUser(uid: String) async {
        if userCache[uid] != nil { return }
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let user = try? snapshot.data(as: QuadUser.self) {
                self.userCache[uid] = user
            }
        } catch {
            print("❌ Failed to load user:", error)
        }
    }

    func sendMessage(courseId: String) async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let chatRef = db.collection("courseChats").document(courseId)

        do {
            try await db.runTransaction { transaction, errorPointer -> Any? in

                let chatSnapshot: DocumentSnapshot
                do {
                    chatSnapshot = try transaction.getDocument(chatRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }

                let currentIndex = chatSnapshot.data()?["lastMessageIndex"] as? Int ?? 0
                let newIndex = currentIndex + 1

                let messageRef = chatRef.collection("messages").document()

                transaction.setData([
                    "senderId": self.uid,
                    "senderName": self.currentUsername,
                    "text": trimmed,
                    "timestamp": FieldValue.serverTimestamp(),
                    "messageIndex": newIndex,
                    "replyToMessageId": self.replyingTo?.documentId as Any,
                    "replyToText": self.replyingTo?.text as Any,
                    "replyToSenderName": self.replyingTo?.senderName as Any
                ], forDocument: messageRef)

                transaction.updateData([
                    "lastMessage": trimmed,
                    "lastMessageTime": FieldValue.serverTimestamp(),
                    "lastSenderId": self.uid,
                    "lastSenderName": self.currentUsername,
                    "lastMessageIndex": newIndex
                ], forDocument: chatRef)

                return nil
            }

            messageText = ""
            replyingTo = nil
            await markAsRead(courseId: courseId)

        } catch {
            print("❌ Send message transaction error:", error)
        }
    }

    func startTypingListener(courseId: String) {
        typingListener?.remove()

        typingListener = db.collection("courseChats")
            .document(courseId)
            .collection("typing")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }

                var users: [String: (username: String, updatedAt: Date)] = [:]

                snapshot?.documents.forEach { doc in
                    let typingUid = doc.documentID
                    let username = doc.data()["username"] as? String ?? "Someone"
                    let updatedAt = doc.data()["updatedAt"] as? Timestamp

                    if typingUid != self.uid, let updatedAt {
                        let seconds = Date().timeIntervalSince(updatedAt.dateValue())
                        if seconds < 3 {
                            users[typingUid] = (username: username, updatedAt: updatedAt.dateValue())
                        }
                    }
                }

                self.typingUsers = users
            }

        typingRefreshTimer?.invalidate()
        typingRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                let now = Date()
                self.typingUsers = self.typingUsers.filter { _, value in
                    now.timeIntervalSince(value.updatedAt) < 3
                }
            }
        }
    }

    func loadMoreMessages(courseId: String) {
        guard !isFetchingMore else { return }
        guard let lastDoc = lastDocument else { return }

        isFetchingMore = true
        isLoadingMore = true

        let query = db.collection("courseChats")
            .document(courseId)
            .collection("messages")
            .order(by: "messageIndex", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: pageSize)

        query.getDocuments { [weak self] snapshot, _ in
            guard let self else { return }

            defer {
                self.isFetchingMore = false
                self.isLoadingMore = false
            }

            guard let docs = snapshot?.documents, !docs.isEmpty else { return }

            self.lastDocument = docs.last

            let fetched = docs.compactMap { try? $0.data(as: CourseMessage.self) }
            let reversed = fetched.reversed()

            // ✅ append (내림차순 쿼리를 뒤집었으니 "더 옛날"이 뒤에 붙는 구조면 UI가 꼬일 수 있음)
            // 너의 현재 구조(최신이 아래)에서는 "옛날 메시지는 앞에" 붙는 게 정석임:
            self.messages.insert(contentsOf: reversed, at: 0)

            let senderIds = Set(reversed.map { $0.senderId })
            Task {
                for id in senderIds {
                    await self.loadUser(uid: id)
                }
            }
        }
    }

    func setTyping(courseId: String) async {
        guard !uid.isEmpty else { return }
        guard !currentUsername.isEmpty else { return }

        let ref = db.collection("courseChats")
            .document(courseId)
            .collection("typing")
            .document(uid)

        do {
            try await ref.setData([
                "username": currentUsername,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        } catch {
            print("❌ typing write error:", error)
        }
    }

    func markAsRead(courseId: String) async {
        guard !uid.isEmpty else { return }

        let chatRef = db.collection("courseChats").document(courseId)
        do {
            let chatSnapshot = try await chatRef.getDocument()
            let lastIndex = chatSnapshot.data()?["lastMessageIndex"] as? Int ?? 0

            try await chatRef
                .collection("readStatus")
                .document(uid)
                .setData(["lastReadIndex": lastIndex], merge: true)

        } catch {
            print("❌ markAsRead error:", error)
        }
    }

    deinit {
        listener?.remove()
        typingListener?.remove()
        typingRefreshTimer?.invalidate()
        readStatusListener?.remove()
    }
}
