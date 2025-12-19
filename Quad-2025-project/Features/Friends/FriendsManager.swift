//
//  FriendsManager.swift
//  Quad-2025-project
//
//  Unified friend management for the entire app
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
class FriendsManager: ObservableObject {

    // MARK: - Singleton

    static let shared = FriendsManager()

    // MARK: - Published Properties

    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []  // Incoming requests
    @Published var sentRequests: [FriendRequest] = []  // Outgoing requests
    @Published var searchResults: [FriendSearchResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let db = Firestore.firestore()
    private var friendsListener: ListenerRegistration?
    private var requestsListener: ListenerRegistration?
    private var sentRequestsListener: ListenerRegistration?

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Initialization

    private init() {
        // Don't start listeners here - user might not be logged in yet
        print("🔧 FriendsManager singleton initialized")
    }

    deinit {
        friendsListener?.remove()
        requestsListener?.remove()
        sentRequestsListener?.remove()
    }

    // MARK: - Real-time Listeners

    public func startListening() {
        guard let userId = currentUserId else {
            print("❌ FriendsManager: No user ID for listening")
            return
        }

        // Remove existing listeners if any
        friendsListener?.remove()
        requestsListener?.remove()
        sentRequestsListener?.remove()

        print("👂 FriendsManager: Starting listeners for user: \(userId)")

        // Listen to friends
        print("🔥 Setting up friends listener for userId: \(userId)")
        friendsListener = db.collection("friends")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else {
                    print("⚠️ Self is nil in friends listener")
                    return
                }

                if let error = error {
                    print("❌ Error fetching friends: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("📭 No friends documents found")
                    return
                }

                print(
                    "👂 Friends listener FIRED - \(documents.count) documents found for userId: \(userId)"
                )
                print("   📍 Listener triggered at: \(Date())")

                let fetchedFriends = documents.compactMap { doc -> Friend? in
                    if let friend = try? doc.data(as: Friend.self) {
                        print("   - Friend doc ID: \(doc.documentID)")
                        print(
                            "     userId: \(friend.userId), friendId: \(friend.friendId), friendUsername: \(friend.friendUsername)"
                        )
                        return friend
                    } else {
                        print("   ❌ Failed to decode friend document: \(doc.documentID)")
                    }
                    return nil
                }

                Task { @MainActor in
                    let oldCount = self.friends.count
                    self.friends = fetchedFriends
                    let newCount = fetchedFriends.count
                    print("✅ Updated friends array: \(oldCount) → \(newCount) for user \(userId)")
                    if fetchedFriends.isEmpty {
                        print("⚠️ Friends list is EMPTY for user \(userId)")
                    } else {
                        print(
                            "✅ Friends: \(fetchedFriends.map { $0.friendUsername }.joined(separator: ", "))"
                        )
                    }
                }
            }

        // Listen to incoming friend requests
        requestsListener = db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error fetching friend requests: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let requests = documents.compactMap { doc -> FriendRequest? in
                    try? doc.data(as: FriendRequest.self)
                }

                Task { @MainActor in
                    self.friendRequests = requests
                    print("📬 Received \(requests.count) friend requests")
                }
            }

        // Listen to sent friend requests
        sentRequestsListener = db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error fetching sent requests: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let requests = documents.compactMap { doc -> FriendRequest? in
                    try? doc.data(as: FriendRequest.self)
                }

                Task { @MainActor in
                    self.sentRequests = requests
                    print("📤 Sent \(requests.count) friend requests")
                }
            }
    }

    // MARK: - Send Friend Request

    func sendFriendRequest(to userId: String, username: String, message: String? = nil) async throws
    {
        guard let currentUserId = currentUserId else {
            throw NSError(
                domain: "FriendsManager", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        guard currentUserId != userId else {
            throw NSError(
                domain: "FriendsManager", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Cannot send friend request to yourself"])
        }

        // Check if already friends
        let existingFriendship = try await db.collection("friends")
            .whereField("userId", isEqualTo: currentUserId)
            .whereField("friendId", isEqualTo: userId)
            .getDocuments()

        if !existingFriendship.documents.isEmpty {
            throw NSError(
                domain: "FriendsManager", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Already friends"])
        }

        // Check if request already exists
        let existingRequest = try await db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()

        if !existingRequest.documents.isEmpty {
            throw NSError(
                domain: "FriendsManager", code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Request already sent"])
        }

        // Get current user info
        let currentUserDoc = try await db.collection("users").document(currentUserId).getDocument()
        guard let currentUserData = currentUserDoc.data(),
            let currentUsername = currentUserData["username"] as? String
        else {
            throw NSError(
                domain: "FriendsManager", code: 5,
                userInfo: [NSLocalizedDescriptionKey: "Could not fetch user data"])
        }

        let currentUserProfileImage = currentUserData["profileImageURL"] as? String

        // Get target user info
        let targetUserDoc = try await db.collection("users").document(userId).getDocument()
        let targetUserData = targetUserDoc.data()
        let targetProfileImage = targetUserData?["profileImageURL"] as? String

        // Create friend request
        let request = FriendRequest(
            fromUserId: currentUserId,
            toUserId: userId,
            fromUsername: currentUsername,
            toUsername: username,
            fromProfileImage: currentUserProfileImage,
            toProfileImage: targetProfileImage,
            status: .pending,
            createdAt: Date(),
            respondedAt: nil,
            message: message
        )

        try db.collection("friendRequests").addDocument(from: request)

        print("✅ Friend request sent to \(username)")

        // Send notification
        await sendFriendRequestNotification(toUserId: userId, fromUsername: currentUsername)
    }

    // MARK: - Accept Friend Request

    func acceptFriendRequest(_ request: FriendRequest) async throws {
        guard let requestId = request.id else {
            throw NSError(
                domain: "FriendsManager", code: 6,
                userInfo: [NSLocalizedDescriptionKey: "Invalid request"])
        }

        guard let currentUserId = currentUserId else {
            throw NSError(
                domain: "FriendsManager", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        print("👥 Accepting friend request from \(request.fromUsername)")
        print("📋 Request details:")
        print("   - fromUserId: \(request.fromUserId)")
        print("   - toUserId: \(request.toUserId)")
        print("   - fromUsername: \(request.fromUsername)")
        print("   - toUsername: \(request.toUsername)")
        print("   - currentUserId: \(currentUserId)")

        // Get acceptor's actual username from Firestore
        let acceptorUserDoc = try await db.collection("users").document(currentUserId).getDocument()
        guard let acceptorUserData = acceptorUserDoc.data(),
            let acceptorUsername = acceptorUserData["username"] as? String
        else {
            throw NSError(
                domain: "FriendsManager", code: 7,
                userInfo: [NSLocalizedDescriptionKey: "Could not fetch acceptor user data"])
        }

        let acceptorProfileImage = acceptorUserData["profileImageURL"] as? String

        print("   - Fetched acceptor username: \(acceptorUsername)")

        // Check if friendship already exists to prevent duplicates
        let existingFriendship1 = try await db.collection("friends")
            .whereField("userId", isEqualTo: currentUserId)
            .whereField("friendId", isEqualTo: request.fromUserId)
            .getDocuments()

        let existingFriendship2 = try await db.collection("friends")
            .whereField("userId", isEqualTo: request.fromUserId)
            .whereField("friendId", isEqualTo: currentUserId)
            .getDocuments()

        if !existingFriendship1.documents.isEmpty || !existingFriendship2.documents.isEmpty {
            print("⚠️ Friendship already exists, deleting request only")
            try await db.collection("friendRequests").document(requestId).delete()
            return
        }

        // Update request status
        try await db.collection("friendRequests").document(requestId).updateData([
            "status": "accepted",
            "respondedAt": FieldValue.serverTimestamp(),
        ])

        // Create bidirectional friendship
        let friend1 = Friend(
            userId: currentUserId,
            friendId: request.fromUserId,
            friendUsername: request.fromUsername,
            friendEmail: nil,
            friendProfileImage: request.fromProfileImage,
            createdAt: Date(),
            acceptedAt: Date()
        )

        let friend2 = Friend(
            userId: request.fromUserId,
            friendId: currentUserId,
            friendUsername: acceptorUsername,
            friendEmail: nil,
            friendProfileImage: acceptorProfileImage,
            createdAt: Date(),
            acceptedAt: Date()
        )

        print("📝 Creating friend1 (for acceptor):")
        print("   - userId: \(friend1.userId)")
        print("   - friendId: \(friend1.friendId)")
        print("   - friendUsername: \(friend1.friendUsername)")

        print("📝 Creating friend2 (for sender):")
        print("   - userId: \(friend2.userId)")
        print("   - friendId: \(friend2.friendId)")
        print("   - friendUsername: \(friend2.friendUsername)")

        let doc1Ref = try db.collection("friends").addDocument(from: friend1)
        print("✅ friend1 saved with ID: \(doc1Ref.documentID)")

        let doc2Ref = try db.collection("friends").addDocument(from: friend2)
        print("✅ friend2 saved with ID: \(doc2Ref.documentID)")

        print("🎉 Friend request accepted - bidirectional friendship created!")
        print("   - Acceptor (\(currentUserId)) should see \(request.fromUsername)")
        print("   - Sender (\(request.fromUserId)) should see \(request.toUsername)")

        // Delete the request document to clean up
        try await db.collection("friendRequests").document(requestId).delete()
        print("🗑️ Friend request document deleted")

        // Send notification
        await sendFriendAcceptedNotification(toUserId: request.fromUserId)
    }

    // MARK: - Decline Friend Request

    func declineFriendRequest(_ request: FriendRequest) async throws {
        guard let requestId = request.id else {
            throw NSError(
                domain: "FriendsManager", code: 6,
                userInfo: [NSLocalizedDescriptionKey: "Invalid request"])
        }

        try await db.collection("friendRequests").document(requestId).updateData([
            "status": "declined",
            "respondedAt": FieldValue.serverTimestamp(),
        ])

        print("❌ Friend request declined")
    }

    // MARK: - Cancel Sent Request

    func cancelFriendRequest(_ request: FriendRequest) async throws {
        guard let requestId = request.id else {
            throw NSError(
                domain: "FriendsManager", code: 6,
                userInfo: [NSLocalizedDescriptionKey: "Invalid request"])
        }

        try await db.collection("friendRequests").document(requestId).updateData([
            "status": "cancelled",
            "respondedAt": FieldValue.serverTimestamp(),
        ])

        print("🔄 Friend request cancelled")
    }

    // MARK: - Remove Friend

    func removeFriend(_ friend: Friend) async throws {
        guard let friendshipId = friend.id else {
            throw NSError(
                domain: "FriendsManager", code: 7,
                userInfo: [NSLocalizedDescriptionKey: "Invalid friendship"])
        }

        guard let currentUserId = currentUserId else {
            throw NSError(
                domain: "FriendsManager", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        print("🗑️ Removing friendship with \(friend.friendUsername)")
        print("   - Deleting friend1 (my side) doc ID: \(friendshipId)")

        // Delete both sides of the friendship
        try await db.collection("friends").document(friendshipId).delete()
        print("   ✅ Deleted friend1")

        let reverseFriendship = try await db.collection("friends")
            .whereField("userId", isEqualTo: friend.friendId)
            .whereField("friendId", isEqualTo: currentUserId)
            .getDocuments()

        print("   - Found \(reverseFriendship.documents.count) reverse friendship documents")

        for doc in reverseFriendship.documents {
            print("   - Deleting friend2 (their side) doc ID: \(doc.documentID)")
            do {
                try await doc.reference.delete()
                print("   ✅ Deleted friend2")
            } catch {
                print("   ❌ Failed to delete friend2: \(error.localizedDescription)")
                throw error
            }
        }

        print("💔 Friendship removed with \(friend.friendUsername)")
    }

    // MARK: - Search Users

    func searchUsers(query: String) async {
        print("🔍 DEBUG: Starting search for: '\(query)'")

        guard !query.isEmpty else {
            print("❌ DEBUG: Query is empty")
            searchResults = []
            return
        }

        guard let currentUserId = currentUserId else {
            print("❌ DEBUG: No current user ID")
            return
        }

        print("✅ DEBUG: Current user ID: \(currentUserId)")
        isLoading = true

        do {
            print("🔍 DEBUG: Querying Firestore for username starting with: '\(query)'")
            // Try searching by username_lower first (case-insensitive)
            var snapshot = try await db.collection("users")
                .whereField("username_lower", isGreaterThanOrEqualTo: query.lowercased())
                .whereField("username_lower", isLessThanOrEqualTo: query.lowercased() + "\u{f8ff}")
                .limit(to: 20)
                .getDocuments()

            print("📦 DEBUG: Found \(snapshot.documents.count) users with username_lower")

            // If no results, try exact match on username
            if snapshot.documents.isEmpty {
                print("🔄 DEBUG: Trying exact match search on username field...")
                snapshot = try await db.collection("users")
                    .whereField("username", isEqualTo: query)
                    .limit(to: 20)
                    .getDocuments()
                print("📦 DEBUG: Found \(snapshot.documents.count) users with exact match")
            }

            print("📦 DEBUG: Total found: \(snapshot.documents.count) users in Firestore")
            var results: [FriendSearchResult] = []

            for doc in snapshot.documents {
                let data = doc.data()
                print(
                    "   👤 DEBUG: Processing user doc - username: \(data["username"] ?? "nil"), uid: \(data["uid"] ?? "nil")"
                )

                guard let username = data["username"] as? String,
                    let userId = data["uid"] as? String,
                    userId != currentUserId
                else {
                    print("   ⚠️ DEBUG: Skipping user - invalid data or is current user")
                    continue
                }

                // Check if already friends
                let friendCheck = try await db.collection("friends")
                    .whereField("userId", isEqualTo: currentUserId)
                    .whereField("friendId", isEqualTo: userId)
                    .getDocuments()

                let isFriend = !friendCheck.documents.isEmpty

                // Check for pending requests
                let sentRequestCheck = try await db.collection("friendRequests")
                    .whereField("fromUserId", isEqualTo: currentUserId)
                    .whereField("toUserId", isEqualTo: userId)
                    .whereField("status", isEqualTo: "pending")
                    .getDocuments()

                let receivedRequestCheck = try await db.collection("friendRequests")
                    .whereField("fromUserId", isEqualTo: userId)
                    .whereField("toUserId", isEqualTo: currentUserId)
                    .whereField("status", isEqualTo: "pending")
                    .getDocuments()

                let hasPendingRequest =
                    !sentRequestCheck.documents.isEmpty || !receivedRequestCheck.documents.isEmpty
                let requestSentByMe = !sentRequestCheck.documents.isEmpty

                let result = FriendSearchResult(
                    id: userId,
                    username: username,
                    email: data["email"] as? String,
                    profileImageURL: data["profileImageURL"] as? String,
                    major: data["major"] as? String,
                    year: data["year"] as? String,
                    isFriend: isFriend,
                    hasPendingRequest: hasPendingRequest,
                    requestSentByMe: requestSentByMe
                )

                print(
                    "   ✅ DEBUG: Added to results - \(username), isFriend: \(isFriend), hasPending: \(hasPendingRequest)"
                )
                results.append(result)
            }

            print("✅ DEBUG: Search complete - returning \(results.count) results")
            await MainActor.run {
                self.searchResults = results
                self.isLoading = false
            }

        } catch {
            print("❌ DEBUG: Search error: \(error.localizedDescription)")
            print("❌ DEBUG: Full error: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Get Friends List (for sharing, etc.)

    func getFriendsList() async -> [UserMini] {
        return friends.map { friend in
            UserMini(
                uid: friend.friendId,
                username: friend.friendUsername,
                profileImageURL: friend.friendProfileImage ?? ""
            )
        }
    }

    // MARK: - Check Friendship Status

    func isFriend(userId: String) async -> Bool {
        guard let currentUserId = currentUserId else { return false }

        do {
            let snapshot = try await db.collection("friends")
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("friendId", isEqualTo: userId)
                .getDocuments()

            return !snapshot.documents.isEmpty
        } catch {
            print("❌ Error checking friendship: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Notifications

    private func sendFriendRequestNotification(toUserId: String, fromUsername: String) async {
        let notificationVM = NotificationViewModel()
        notificationVM.sendFollowNotification(toUserId: toUserId)  // Reusing follow notification
    }

    private func sendFriendAcceptedNotification(toUserId: String) async {
        let notificationVM = NotificationViewModel()
        notificationVM.sendFollowAcceptedNotification(toUserId: toUserId)  // Reusing follow accepted notification
    }
}
