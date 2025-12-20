//
//  StudyFriendsManager.swift
//  Quad-2025-project
//
//  Manages study friends, friend requests, and real-time study tracking
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
class StudyFriendsManager: ObservableObject {

    @Published var friends: [StudyFriend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var sentRequests: [FriendRequest] = []
    @Published var friendsStudyStatus: [FriendStudyStatus] = []
    @Published var searchResults: [FriendSearchResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var friendsListener: ListenerRegistration?
    private var requestsListener: ListenerRegistration?
    private var statusListeners: [String: ListenerRegistration] = [:]
    private var timer: Timer?

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        startListening()
        startStatusUpdateTimer()
    }

    deinit {
        friendsListener?.remove()
        requestsListener?.remove()
        statusListeners.values.forEach { $0.remove() }
        timer?.invalidate()
    }

    // MARK: - Listeners

    func startListening() {
        guard let userId = currentUserId else {
            print("❌ No user ID for listening to friends")
            return
        }

        print("👂 Starting to listen for study friends...")

        // Listen to friends
        friendsListener = db.collection("studyFriends")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error fetching friends: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                print("📦 Received \(documents.count) friendship documents from Firebase")

                let fetchedFriends = documents.compactMap { doc -> StudyFriend? in
                    do {
                        let friend = try doc.data(as: StudyFriend.self)
                        print("  ✅ Friend: \(friend.friendUsername) (ID: \(friend.friendId))")
                        return friend
                    } catch {
                        print("  ❌ Failed to decode friend: \(error.localizedDescription)")
                        return nil
                    }
                }

                Task { @MainActor in
                    self.friends = fetchedFriends
                    print("✅ Loaded \(fetchedFriends.count) study friends")
                    print(
                        "   Friend list: \(fetchedFriends.map { $0.friendUsername }.joined(separator: ", "))"
                    )

                    // Start listening to each friend's study status
                    self.startListeningToFriendsStatus()
                }
            }

        // Listen to incoming friend requests
        requestsListener = db.collection("studyFriendRequests")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error fetching friend requests: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let fetchedRequests = documents.compactMap { doc -> FriendRequest? in
                    try? doc.data(as: FriendRequest.self)
                }

                Task { @MainActor in
                    self.friendRequests = fetchedRequests
                    print("📬 Received \(fetchedRequests.count) friend requests")
                }
            }

        // Listen to sent friend requests
        db.collection("studyFriendRequests")
            .whereField("fromUserId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error fetching sent requests: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let fetchedSentRequests = documents.compactMap { doc -> FriendRequest? in
                    try? doc.data(as: FriendRequest.self)
                }

                Task { @MainActor in
                    self.sentRequests = fetchedSentRequests
                    print("📤 \(fetchedSentRequests.count) sent requests")
                }
            }
    }

    func stopListening() {
        print("🛑 Stopping all listeners...")
        friendsListener?.remove()
        friendsListener = nil
        requestsListener?.remove()
        requestsListener = nil
        statusListeners.values.forEach { $0.remove() }
        statusListeners.removeAll()
        print("✅ All listeners stopped")
    }

    // MARK: - Friend Status Tracking

    func startListeningToFriendsStatus() {
        // Remove old listeners
        statusListeners.values.forEach { $0.remove() }
        statusListeners.removeAll()

        print("👂 Starting status listeners for \(friends.count) friends")

        // Create listeners for each friend
        for friend in friends {
            let friendId = friend.friendId
            print("📡 Setting up listener for friend: \(friend.friendUsername) (ID: \(friendId))")

            // First check if friend has sharing enabled
            db.collection("users").document(friendId).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }

                // Check privacy setting
                let shareStudyStatus = snapshot?.data()?["shareStudyStatus"] as? Bool ?? true

                if !shareStudyStatus {
                    print("🔒 Friend \(friend.friendUsername) has sharing disabled")
                    Task { @MainActor in
                        self.updateFriendStatus(
                            friendId: friendId,
                            username: friend.friendUsername,
                            isStudying: false,
                            sessionId: nil,
                            startTime: nil
                        )
                    }
                    return
                }

                print("   Querying studySessions where userId=\(friendId) AND isActive=true")

                // IMMEDIATE: Check for active sessions right now
                self.db.collection("studySessions")
                    .whereField("userId", isEqualTo: friendId)
                    .whereField("isActive", isEqualTo: true)
                    .limit(to: 1)
                    .getDocuments { [weak self] snapshot, error in
                        guard let self = self else { return }

                        if let error = error {
                            print(
                                "❌ Initial check error for \(friendId): \(error.localizedDescription)"
                            )
                        } else if let doc = snapshot?.documents.first,
                            let session = try? doc.data(as: StudySession.self)
                        {
                            print("🟢 INITIAL: Friend \(friend.friendUsername) IS STUDYING")
                            print("   Session ID: \(session.id ?? "unknown")")
                            print("   Start time: \(session.startTime)")
                            print(
                                "   Duration so far: \(Int(Date().timeIntervalSince(session.startTime)))s"
                            )
                            Task { @MainActor in
                                self.updateFriendStatus(
                                    friendId: friendId,
                                    username: friend.friendUsername,
                                    isStudying: true,
                                    sessionId: session.id,
                                    startTime: session.startTime
                                )
                            }
                        } else {
                            print("⚫ INITIAL: Friend \(friend.friendUsername) NOT studying")
                            print("   No active sessions found")
                            Task { @MainActor in
                                self.updateFriendStatus(
                                    friendId: friendId,
                                    username: friend.friendUsername,
                                    isStudying: false,
                                    sessionId: nil,
                                    startTime: nil
                                )
                            }
                        }
                    }

                // REAL-TIME: Set up listener for changes
                let listener = self.db.collection("studySessions")
                    .whereField("userId", isEqualTo: friendId)
                    .whereField("isActive", isEqualTo: true)
                    .addSnapshotListener { [weak self] snapshot, error in
                        guard let self = self else { return }

                        if let error = error {
                            print(
                                "❌ Error tracking friend \(friendId): \(error.localizedDescription)"
                            )
                            return
                        }

                        // Check if friend has active session
                        if let activeSession = snapshot?.documents.first,
                            let session = try? activeSession.data(as: StudySession.self)
                        {
                            print(
                                "🟢 Friend \(friend.friendUsername) IS STUDYING - Session: \(session.id ?? "unknown")"
                            )
                            print("   ⏱️ Started at: \(session.startTime)")

                            // Friend is studying
                            Task { @MainActor in
                                self.updateFriendStatus(
                                    friendId: friendId,
                                    username: friend.friendUsername,
                                    isStudying: true,
                                    sessionId: session.id,
                                    startTime: session.startTime
                                )
                            }
                        } else {
                            print("⚫ Friend \(friend.friendUsername) is NOT studying")

                            // Friend is not studying
                            Task { @MainActor in
                                self.updateFriendStatus(
                                    friendId: friendId,
                                    username: friend.friendUsername,
                                    isStudying: false,
                                    sessionId: nil,
                                    startTime: nil
                                )
                            }
                        }
                    }

                self.statusListeners[friendId] = listener
            }
        }

        // Load today and week totals for all friends
        loadFriendsStudyTotals()
    }

    func updateFriendStatus(
        friendId: String, username: String, isStudying: Bool, sessionId: String?, startTime: Date?
    ) {
        Task { @MainActor in
            if let index = self.friendsStudyStatus.firstIndex(where: { $0.id == friendId }) {
                // Update existing status
                var status = self.friendsStudyStatus[index]
                status.isStudying = isStudying
                status.currentSessionId = sessionId
                status.sessionStartTime = startTime

                if isStudying, let startTime = startTime {
                    status.elapsedTime = Date().timeIntervalSince(startTime)
                    print("🔄 Updated \(username): STUDYING for \(status.formattedElapsedTime)")
                } else {
                    status.elapsedTime = 0
                    print("🔄 Updated \(username): NOT studying")
                }

                status.lastUpdated = Date()
                self.friendsStudyStatus[index] = status
            } else {
                // Create new status
                let status = FriendStudyStatus(
                    id: friendId,
                    userId: friendId,
                    username: username,
                    isStudying: isStudying,
                    currentSessionId: sessionId,
                    sessionStartTime: startTime,
                    elapsedTime: isStudying && startTime != nil
                        ? Date().timeIntervalSince(startTime!) : 0,
                    todayTotalTime: 0,
                    weekTotalTime: 0,
                    lastUpdated: Date()
                )
                self.friendsStudyStatus.append(status)
                print(
                    "✨ Created new status for \(username): \(isStudying ? "STUDYING" : "NOT studying")"
                )
            }

            print("📊 Total statuses tracked: \(self.friendsStudyStatus.count)")
        }
    }

    func startStatusUpdateTimer() {
        // Invalidate existing timer
        timer?.invalidate()

        // Update elapsed time for active studying friends every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                for index in self.friendsStudyStatus.indices {
                    if self.friendsStudyStatus[index].isStudying,
                        let startTime = self.friendsStudyStatus[index].sessionStartTime
                    {
                        let newElapsedTime = Date().timeIntervalSince(startTime)
                        self.friendsStudyStatus[index].elapsedTime = newElapsedTime
                        self.friendsStudyStatus[index].lastUpdated = Date()

                        // Debug log every 5 seconds
                        if Int(newElapsedTime) % 5 == 0 {
                            print(
                                "⏱️ Timer update: \(self.friendsStudyStatus[index].username) - \(Int(newElapsedTime))s"
                            )
                        }
                    }
                }
            }
        }

        // Ensure timer runs even when scrolling
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }

        print("⏰ Status update timer started")
    }

    func loadFriendsStudyTotals() {
        for friend in friends {
            // Check privacy setting before loading totals
            db.collection("users").document(friend.friendId).getDocument {
                [weak self] snapshot, error in
                guard let self = self else { return }

                let shareStudyStatus = snapshot?.data()?["shareStudyStatus"] as? Bool ?? true

                if shareStudyStatus {
                    self.loadTodayTotal(for: friend.friendId)
                    self.loadWeekTotal(for: friend.friendId)
                } else {
                    print("🔒 Skipping totals for \(friend.friendUsername) - sharing disabled")
                }
            }
        }
    }

    func loadTodayTotal(for friendId: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        db.collection("studySessions")
            .whereField("userId", isEqualTo: friendId)
            .whereField("isActive", isEqualTo: false)
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: today))
            .whereField("startTime", isLessThan: Timestamp(date: tomorrow))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print(
                        "❌ Error loading today total for \(friendId): \(error.localizedDescription)"
                    )
                    return
                }

                let sessions =
                    snapshot?.documents.compactMap { doc -> StudySession? in
                        try? doc.data(as: StudySession.self)
                    } ?? []

                let totalTime = sessions.reduce(0.0) { $0 + $1.duration }
                print(
                    "📅 Today total for \(friendId): \(sessions.count) sessions, \(Int(totalTime/60))m"
                )

                DispatchQueue.main.async {
                    if let index = self.friendsStudyStatus.firstIndex(where: { $0.id == friendId })
                    {
                        self.friendsStudyStatus[index].todayTotalTime = totalTime
                        print("✅ Updated today total for friend at index \(index)")
                    } else {
                        print("⚠️ Could not find friend status for \(friendId)")
                    }
                }
            }
    }

    func loadWeekTotal(for friendId: String) {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7

        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)
        else {
            return
        }

        let weekStart = calendar.startOfDay(for: startOfWeek)

        db.collection("studySessions")
            .whereField("userId", isEqualTo: friendId)
            .whereField("isActive", isEqualTo: false)
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: weekStart))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print(
                        "❌ Error loading week total for \(friendId): \(error.localizedDescription)")
                    return
                }

                let sessions =
                    snapshot?.documents.compactMap { doc -> StudySession? in
                        try? doc.data(as: StudySession.self)
                    } ?? []

                let totalTime = sessions.reduce(0.0) { $0 + $1.duration }
                print(
                    "📆 Week total for \(friendId): \(sessions.count) sessions, \(Int(totalTime/60))m"
                )

                DispatchQueue.main.async {
                    if let index = self.friendsStudyStatus.firstIndex(where: { $0.id == friendId })
                    {
                        self.friendsStudyStatus[index].weekTotalTime = totalTime
                        print("✅ Updated week total for friend at index \(index)")
                    } else {
                        print("⚠️ Could not find friend status for \(friendId) to update week total")
                    }
                }
            }
    }

    // MARK: - Search Users

    func searchUsers(query: String) async {
        guard !query.isEmpty, let currentUserId = currentUserId else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
        }

        print("🔍 Searching for users with query: '\(query)'")

        do {
            // Try searching by username_lower first (case-insensitive)
            var snapshot = try await db.collection("users")
                .whereField("username_lower", isGreaterThanOrEqualTo: query.lowercased())
                .whereField("username_lower", isLessThanOrEqualTo: query.lowercased() + "\u{f8ff}")
                .limit(to: 20)
                .getDocuments()

            print("📥 Found \(snapshot.documents.count) users")

            // If no results, try exact match on username
            if snapshot.documents.isEmpty {
                print("🔄 Trying exact match search...")
                snapshot = try await db.collection("users")
                    .whereField("username", isEqualTo: query)
                    .limit(to: 20)
                    .getDocuments()
                print("📥 Found \(snapshot.documents.count) users with exact match")
            }

            let users = snapshot.documents.compactMap { doc -> QuadUser? in
                do {
                    let user = try doc.data(as: QuadUser.self)
                    print("✅ Decoded user: \(user.username)")
                    return user
                } catch {
                    print("❌ Failed to decode user document: \(error.localizedDescription)")
                    return nil
                }
            }

            print("👥 Decoded \(users.count) users successfully")

            // Check friendship status for each user
            var results: [FriendSearchResult] = []

            for user in users where user.id != currentUserId {
                let isFriend = await checkIfFriend(userId: user.id ?? "")
                let (hasPending, sentByMe) = await checkPendingRequest(userId: user.id ?? "")

                let result = FriendSearchResult(
                    id: user.id ?? "",
                    username: user.username,
                    email: user.email,
                    profileImageURL: user.profileImageURL,
                    major: user.major,
                    year: user.year,
                    isFriend: isFriend,
                    hasPendingRequest: hasPending,
                    requestSentByMe: sentByMe
                )
                results.append(result)
            }

            print("✅ Returning \(results.count) search results")

            DispatchQueue.main.async {
                self.searchResults = results
                self.isLoading = false
            }

        } catch {
            print("❌ Error searching users: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func checkIfFriend(userId: String) async -> Bool {
        guard let currentUserId = currentUserId else { return false }

        do {
            let snapshot = try await db.collection("studyFriends")
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("friendId", isEqualTo: userId)
                .whereField("status", isEqualTo: "accepted")
                .getDocuments()

            return !snapshot.documents.isEmpty
        } catch {
            return false
        }
    }

    private func checkPendingRequest(userId: String) async -> (hasPending: Bool, sentByMe: Bool) {
        guard let currentUserId = currentUserId else { return (false, false) }

        do {
            // Check if I sent a request
            let sentSnapshot = try await db.collection("studyFriendRequests")
                .whereField("fromUserId", isEqualTo: currentUserId)
                .whereField("toUserId", isEqualTo: userId)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()

            if !sentSnapshot.documents.isEmpty {
                return (true, true)
            }

            // Check if they sent me a request
            let receivedSnapshot = try await db.collection("studyFriendRequests")
                .whereField("fromUserId", isEqualTo: userId)
                .whereField("toUserId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()

            return (!receivedSnapshot.documents.isEmpty, false)

        } catch {
            return (false, false)
        }
    }

    // MARK: - Friend Requests

    func sendFriendRequest(toUserId: String, toUsername: String, message: String? = nil) async {
        guard let currentUserId = currentUserId else {
            print("❌ No current user")
            return
        }

        // Get current user's username
        guard
            let currentUsername = try? await db.collection("users")
                .document(currentUserId)
                .getDocument()
                .data()?["username"] as? String
        else {
            print("❌ Cannot get current username")
            return
        }

        let request = FriendRequest(
            fromUserId: currentUserId,
            toUserId: toUserId,
            fromUsername: currentUsername,
            toUsername: toUsername,
            status: .pending,
            createdAt: Date(),
            respondedAt: nil,
            message: message
        )

        let requestData: [String: Any] = [
            "fromUserId": request.fromUserId,
            "toUserId": request.toUserId,
            "fromUsername": request.fromUsername,
            "toUsername": request.toUsername,
            "status": request.status.rawValue,
            "createdAt": Timestamp(date: request.createdAt),
            "message": message ?? "",
        ]

        do {
            try await db.collection("studyFriendRequests").addDocument(data: requestData)
            print("✅ Friend request sent to \(toUsername)")
        } catch {
            print("❌ Error sending friend request: \(error.localizedDescription)")
        }
    }

    func acceptFriendRequest(request: FriendRequest) async {
        guard let requestId = request.id, let currentUserId = currentUserId else {
            print("❌ Invalid request or user")
            return
        }

        do {
            // Get current user's username from Firebase
            let currentUserDoc = try await db.collection("users").document(currentUserId)
                .getDocument()
            guard let currentUsername = currentUserDoc.data()?["username"] as? String else {
                print("❌ Cannot get current username")
                return
            }

            print("👥 Accepting request from \(request.fromUsername) to \(currentUsername)")
            print("   Request ID: \(requestId)")
            print("   From User ID: \(request.fromUserId)")
            print("   To User ID (current): \(currentUserId)")

            // Update request status
            try await db.collection("studyFriendRequests")
                .document(requestId)
                .updateData([
                    "status": "accepted",
                    "respondedAt": Timestamp(date: Date()),
                ])
            print("✅ Updated request status to accepted")

            // Create friendship for current user (receiver)
            let friend1 = StudyFriend(
                userId: currentUserId,
                friendId: request.fromUserId,
                friendUsername: request.fromUsername,
                friendEmail: nil,
                status: .accepted,
                createdAt: Date(),
                acceptedAt: Date()
            )

            let friend1Data: [String: Any] = [
                "userId": friend1.userId,
                "friendId": friend1.friendId,
                "friendUsername": friend1.friendUsername,
                "status": friend1.status.rawValue,
                "createdAt": Timestamp(date: friend1.createdAt),
                "acceptedAt": Timestamp(date: friend1.acceptedAt!),
            ]

            let doc1Ref = try await db.collection("studyFriends").addDocument(data: friend1Data)
            print("✅ Created friendship: \(currentUsername) -> \(request.fromUsername)")
            print("   Document ID: \(doc1Ref.documentID)")

            // Create friendship for the sender (so they see the receiver as friend)
            let friend2 = StudyFriend(
                userId: request.fromUserId,
                friendId: currentUserId,
                friendUsername: currentUsername,
                friendEmail: nil,
                status: .accepted,
                createdAt: Date(),
                acceptedAt: Date()
            )

            let friend2Data: [String: Any] = [
                "userId": friend2.userId,
                "friendId": friend2.friendId,
                "friendUsername": friend2.friendUsername,
                "status": friend2.status.rawValue,
                "createdAt": Timestamp(date: friend2.createdAt),
                "acceptedAt": Timestamp(date: friend2.acceptedAt!),
            ]

            let doc2Ref = try await db.collection("studyFriends").addDocument(data: friend2Data)
            print("✅ Created friendship: \(request.fromUsername) -> \(currentUsername)")
            print("   Document ID: \(doc2Ref.documentID)")

            print("🎉 Friend request accepted - bidirectional friendship created!")

            // Verify documents were created
            print("🔍 Verifying friendship documents in Firebase...")
            let verifySnapshot1 = try await db.collection("studyFriends")
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("friendId", isEqualTo: request.fromUserId)
                .getDocuments()
            print(
                "   Receiver (\(currentUsername)) has \(verifySnapshot1.documents.count) friendship(s) with sender"
            )

            for doc in verifySnapshot1.documents {
                print("     - Doc ID: \(doc.documentID)")
                print("       Data: \(doc.data())")
            }

            let verifySnapshot2 = try await db.collection("studyFriends")
                .whereField("userId", isEqualTo: request.fromUserId)
                .whereField("friendId", isEqualTo: currentUserId)
                .getDocuments()
            print(
                "   Sender (\(request.fromUsername)) has \(verifySnapshot2.documents.count) friendship(s) with receiver"
            )

            for doc in verifySnapshot2.documents {
                print("     - Doc ID: \(doc.documentID)")
                print("       Data: \(doc.data())")
            }

            // Force refresh listeners
            print("🔄 Forcing listener refresh...")
            stopListening()
            startListening()

        } catch {
            print("❌ Error accepting friend request: \(error.localizedDescription)")
            print("   Error details: \(error)")
        }
    }

    func declineFriendRequest(request: FriendRequest) async {
        guard let requestId = request.id else { return }

        do {
            try await db.collection("studyFriendRequests")
                .document(requestId)
                .updateData([
                    "status": "declined",
                    "respondedAt": Timestamp(date: Date()),
                ])

            print("✅ Friend request declined")

        } catch {
            print("❌ Error declining friend request: \(error.localizedDescription)")
        }
    }

    func cancelFriendRequest(requestId: String) async {
        do {
            try await db.collection("studyFriendRequests")
                .document(requestId)
                .updateData([
                    "status": "cancelled",
                    "respondedAt": Timestamp(date: Date()),
                ])

            print("✅ Friend request cancelled")

        } catch {
            print("❌ Error cancelling friend request: \(error.localizedDescription)")
        }
    }

    // MARK: - Debug Functions

    func verifyFriendships() async {
        guard let currentUserId = currentUserId else {
            print("❌ No current user")
            return
        }

        print("\n🔍 VERIFYING FRIENDSHIPS FOR CURRENT USER")
        print(String(repeating: "=", count: 50))
        print("Current User ID: \(currentUserId)")

        do {
            // Check all friendships where current user is the userId
            let myFriendshipsSnapshot = try await db.collection("studyFriends")
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: "accepted")
                .getDocuments()

            print("\n📤 OUTGOING: I have \(myFriendshipsSnapshot.documents.count) friend(s)")
            for doc in myFriendshipsSnapshot.documents {
                let data = doc.data()
                let friendId = data["friendId"] as? String ?? "unknown"
                let friendUsername = data["friendUsername"] as? String ?? "unknown"
                print("  ✅ \(friendUsername) (ID: \(friendId))")

                // Check if bidirectional
                let reverseSnapshot = try await db.collection("studyFriends")
                    .whereField("userId", isEqualTo: friendId)
                    .whereField("friendId", isEqualTo: currentUserId)
                    .whereField("status", isEqualTo: "accepted")
                    .getDocuments()

                if reverseSnapshot.documents.isEmpty {
                    print("    ⚠️ WARNING: No reverse friendship found! This is ONE-WAY.")
                } else {
                    print("    ✅ Bidirectional friendship confirmed")
                }
            }

            // Check all friendships where current user is the friendId
            let friendsOfMeSnapshot = try await db.collection("studyFriends")
                .whereField("friendId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: "accepted")
                .getDocuments()

            print("\n📥 INCOMING: \(friendsOfMeSnapshot.documents.count) user(s) have me as friend")
            for doc in friendsOfMeSnapshot.documents {
                let data = doc.data()
                let userId = data["userId"] as? String ?? "unknown"
                let friendUsername = data["friendUsername"] as? String ?? "unknown"
                print("  ✅ User ID: \(userId) has me (\(friendUsername)) as friend")

                // Check if I also have them
                let mySnapshot = try await db.collection("studyFriends")
                    .whereField("userId", isEqualTo: currentUserId)
                    .whereField("friendId", isEqualTo: userId)
                    .whereField("status", isEqualTo: "accepted")
                    .getDocuments()

                if mySnapshot.documents.isEmpty {
                    print("    ⚠️ WARNING: I don't have them as friend! This is ONE-WAY.")
                } else {
                    print("    ✅ I also have them as friend")
                }
            }

            print("\n" + String(repeating: "=", count: 50))

        } catch {
            print("❌ Error verifying friendships: \(error.localizedDescription)")
        }
    }

    func removeFriend(friendId: String) async {
        guard let currentUserId = currentUserId else { return }

        do {
            print("🗑️ Removing friendship between \(currentUserId) and \(friendId)")

            // Remove friendship from current user's side
            let snapshot1 = try await db.collection("studyFriends")
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("friendId", isEqualTo: friendId)
                .getDocuments()

            for doc in snapshot1.documents {
                try await doc.reference.delete()
                print("✅ Deleted friendship doc: \(doc.documentID)")
            }

            // Remove friendship from friend's side (BIDIRECTIONAL)
            let snapshot2 = try await db.collection("studyFriends")
                .whereField("userId", isEqualTo: friendId)
                .whereField("friendId", isEqualTo: currentUserId)
                .getDocuments()

            for doc in snapshot2.documents {
                try await doc.reference.delete()
                print("✅ Deleted friendship doc: \(doc.documentID)")
            }

            print("🎉 Friend removed from BOTH sides - bidirectional removal complete!")

        } catch {
            print("❌ Error removing friend: \(error.localizedDescription)")
        }
    }
}
