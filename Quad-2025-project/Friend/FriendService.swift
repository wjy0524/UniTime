//
//  FriendService.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/23/26.
//

import FirebaseAuth
import FirebaseFirestore

@MainActor
final class FriendService: ObservableObject {

    static let shared = FriendService()
    private init() {}

    private let db = Firestore.firestore()

    @Published var friends: [String] = []
    @Published var sentRequests: [String] = []
    @Published var receivedRequests: [String] = []

    var myUid: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    // MARK: - Load all
    func loadAll() async {
        await loadFriends()
        await loadSentRequests()
        await loadReceivedRequests()
    }

    func loadFriends() async {
        let snap = try? await db
            .collection("users")
            .document(myUid)
            .collection("friends")
            .getDocuments()

        friends = snap?.documents.map { $0.documentID } ?? []
    }

    func loadSentRequests() async {
        let snap = try? await db
            .collection("friend_requests")
            .whereField("fromUid", isEqualTo: myUid)
            .getDocuments()

        sentRequests = snap?.documents.compactMap {
            $0["toUid"] as? String
        } ?? []
    }

    func loadReceivedRequests() async {
        let snap = try? await db
            .collection("friend_requests")
            .whereField("toUid", isEqualTo: myUid)
            .getDocuments()

        receivedRequests = snap?.documents.compactMap {
            $0["fromUid"] as? String
        } ?? []
    }

    // MARK: - Status
    func status(with uid: String) -> FriendStatus {
        if friends.contains(uid) { return .friends }
        if sentRequests.contains(uid) { return .sent }
        if receivedRequests.contains(uid) { return .received }
        return .none
    }

    // MARK: - Actions
    func sendRequest(to uid: String) async {
        if friends.contains(uid) || sentRequests.contains(uid) {
            return
        }

        let requestId = "\(myUid)_\(uid)"
        let ref = db.collection("friend_requests").document(requestId)

        let data: [String: Any] = [
            "fromUid": myUid,
            "toUid": uid,
            "createdAt": Timestamp()
        ]

        do {
            try await ref.setData(data, merge: false)
            await loadAll()
        } catch {
            print("❌ sendRequest failed:", error)
        }
    }


    func acceptRequest(from uid: String) async {
        do {
            // 1️⃣ 내 friends
            try await db.collection("users").document(myUid)
                .collection("friends").document(uid).setData([:])

            // 2️⃣ 상대 friends
            try await db.collection("users").document(uid)
                .collection("friends").document(myUid).setData([:])

            // 3️⃣ 요청 삭제
            let snap = try await db.collection("friend_requests")
                .whereField("fromUid", isEqualTo: uid)
                .whereField("toUid", isEqualTo: myUid)
                .getDocuments()

            for doc in snap.documents {
                try await doc.reference.delete()
            }

            await loadAll()

        } catch {
            print("❌ acceptRequest failed:", error)
        }
    }


    func removeFriend(uid: String) async {
        try? await db.collection("users").document(myUid)
            .collection("friends").document(uid).delete()

        try? await db.collection("users").document(uid)
            .collection("friends").document(myUid).delete()

        await loadAll()
    }
    
    func cancelRequest(to uid: String) async {
        let snap = try? await db.collection("friend_requests")
            .whereField("fromUid", isEqualTo: myUid)
            .whereField("toUid", isEqualTo: uid)
            .getDocuments()

        snap?.documents.forEach { $0.reference.delete() }
        await loadAll()
    }
    func fetchFriendUsers() async -> [Friend] {
        guard !friends.isEmpty else { return [] }

        var result: [Friend] = []

        for uid in friends {
            if let snap = try? await db.collection("users").document(uid).getDocument(),
               let data = snap.data(),
               let username = data["username"] as? String {

                let profileImage = data["profileImageURL"] as? String

                result.append(
                    Friend(
                        uid: uid,
                        username: username,
                        profileImageURL: profileImage
                    )
                )
            }
        }
        return result
    }

}
