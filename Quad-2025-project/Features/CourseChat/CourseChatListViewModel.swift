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
    private var readStatusListeners: [String: ListenerRegistration] = [:]
    private var lastReadIndices: [String: Int] = [:]

    var uid: String? {
        Auth.auth().currentUser?.uid
    }

    func startListening() {

        guard let uid = uid else { return }

        listener?.remove()

        listener = db.collection("courseChats")
            .whereField("members", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, error in

                guard let self else { return }
                guard let docs = snapshot?.documents else { return }

                let chats = docs.compactMap {
                    try? $0.data(as: CourseChat.self)
                }

                self.chats = chats.sorted {
                    ($0.lastMessageTime ?? Date.distantPast) >
                    ($1.lastMessageTime ?? Date.distantPast)
                }

                for chat in self.chats {
                    guard let chatId = chat.id else { continue }

                    let lastIndex = chat.lastMessageIndex ?? 0
                    let lastReadIndex = self.lastReadIndices[chatId] ?? 0

                    // 🔥 ONLY readStatus 기반 계산
                    self.unreadCounts[chatId] =
                        max(0, lastIndex - lastReadIndex)
                }

                // 🔥 readStatus listener 등록
                for chat in chats {

                    guard let chatId = chat.id else { continue }

                    if self.readStatusListeners[chatId] != nil {
                        continue
                    }

                    let readListener = self.db.collection("courseChats")
                        .document(chatId)
                        .collection("readStatus")
                        .document(uid)
                        .addSnapshotListener { [weak self] snapshot, _ in

                            guard let self else { return }

                            let lastReadIndex =
                                snapshot?.data()?["lastReadIndex"] as? Int ?? 0

                            self.lastReadIndices[chatId] = lastReadIndex

                            guard let updatedChat =
                                self.chats.first(where: { $0.id == chatId })
                            else { return }

                            let lastIndex =
                                updatedChat.lastMessageIndex ?? 0

                            self.unreadCounts[chatId] =
                                max(0, lastIndex - lastReadIndex)
                        }

                    self.readStatusListeners[chatId] = readListener
                }

                // 🔥 삭제된 채팅 listener 정리
                let activeChatIds =
                    Set(chats.compactMap { $0.id })

                let listenersToRemove =
                    self.readStatusListeners.keys.filter {
                        !activeChatIds.contains($0)
                    }

                for chatId in listenersToRemove {
                    self.readStatusListeners[chatId]?.remove()
                    self.readStatusListeners.removeValue(forKey: chatId)
                }
            }
    }

    deinit {
        listener?.remove()
        for (_, listener) in readStatusListeners {
            listener.remove()
        }
    }
}
