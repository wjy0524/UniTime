//
//  NotificationViewModel.swift
//  Quad-2025-project
//
//  Created on Notification Feature Implementation
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Don't auto-start listening - let caller decide
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Fetch Notifications

    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ NOTIFICATIONS: No authenticated user found")
            return
        }

        print("✅ NOTIFICATIONS: Starting to listen for user: \(userId)")

        listener = db.collection("notifications")
            .whereField("toUserId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ NOTIFICATIONS ERROR: \(error.localizedDescription)")
                    print("🔥 Full error: \(error)")

                    // Check if it's an index error
                    if error.localizedDescription.contains("index") {
                        print("⚠️ THIS IS AN INDEX ERROR - You need to create a composite index")
                        print(
                            "📋 Index needed: notifications collection with fields: toUserId (Ascending), timestamp (Descending)"
                        )
                    }

                    self.errorMessage =
                        "Failed to load notifications: \(error.localizedDescription)"
                    self.showingError = true
                    return
                }

                print("✅ NOTIFICATIONS: Query successful")
                print("📊 Number of documents: \(snapshot?.documents.count ?? 0)")

                guard let documents = snapshot?.documents else {
                    print("⚠️ NOTIFICATIONS: No documents in snapshot")
                    return
                }

                self.notifications = documents.compactMap { doc in
                    do {
                        let notification = try doc.data(as: AppNotification.self)
                        print(
                            "✅ Decoded notification: \(notification.type.rawValue) - \(notification.message)"
                        )
                        return notification
                    } catch {
                        print("❌ Failed to decode notification \(doc.documentID): \(error)")
                        return nil
                    }
                }

                self.unreadCount = self.notifications.filter { !$0.isRead }.count
                print(
                    "✅ NOTIFICATIONS: Loaded \(self.notifications.count) notifications, \(self.unreadCount) unread"
                )
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Mark as Read

    func markAsRead(_ notification: AppNotification) {
        guard let notificationId = notification.id else { return }

        db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ]) { error in
            if let error = error {
                print("Error marking notification as read: \(error.localizedDescription)")
            }
        }
    }

    func markAllAsRead() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let unreadNotifications = notifications.filter { !$0.isRead }

        for notification in unreadNotifications {
            if let notificationId = notification.id {
                db.collection("notifications").document(notificationId).updateData([
                    "isRead": true
                ])
            }
        }
    }

    // MARK: - Delete Notification

    func deleteNotification(_ notification: AppNotification) {
        guard let notificationId = notification.id else { return }

        db.collection("notifications").document(notificationId).delete { error in
            if let error = error {
                self.errorMessage = "Failed to delete notification: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }

    // MARK: - Create Notification

    func sendNotification(
        type: NotificationType,
        toUserId: String,
        message: String,
        timetableShareId: String? = nil,
        postId: String? = nil,
        eventId: String? = nil
    ) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ SEND NOTIFICATION: No current user")
            return
        }

        print("🔔 SEND NOTIFICATION: Preparing \(type.rawValue) notification to \(toUserId)")

        // Create a direct reference to avoid self issues
        let db = Firestore.firestore()

        // Fetch current user info
        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let error = error {
                print(
                    "❌ SEND NOTIFICATION: Failed to fetch user data - \(error.localizedDescription)"
                )
                return
            }

            guard let data = snapshot?.data(),
                let username = data["username"] as? String
            else {
                print("❌ SEND NOTIFICATION: No username found in user document")
                return
            }

            let profileImageURL = data["profileImageURL"] as? String

            let notification = AppNotification(
                type: type,
                fromUserId: currentUserId,
                fromUsername: username,
                fromUserProfileImage: profileImageURL,
                toUserId: toUserId,
                message: message,
                timetableShareId: timetableShareId,
                postId: postId,
                eventId: eventId
            )

            print("📝 SEND NOTIFICATION: Created notification object from \(username)")

            do {
                let docRef = try db.collection("notifications").addDocument(from: notification)
                print(
                    "✅ SEND NOTIFICATION: Successfully saved to Firestore with ID: \(docRef.documentID)"
                )
            } catch {
                print("❌ SEND NOTIFICATION ERROR: \(error.localizedDescription)")
                print("🔥 Full error: \(error)")
            }
        }
    }

    // MARK: - Handle Follow Notification

    func sendFollowNotification(toUserId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ FOLLOW NOTIFICATION: No current user")
            return
        }

        print("🔔 FOLLOW NOTIFICATION: Attempting to send to \(toUserId)")

        let db = Firestore.firestore()

        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let error = error {
                print(
                    "❌ FOLLOW NOTIFICATION: Failed to fetch username - \(error.localizedDescription)"
                )
                return
            }

            guard let data = snapshot?.data(),
                let username = data["username"] as? String
            else {
                print("❌ FOLLOW NOTIFICATION: No username found")
                return
            }

            print("✅ FOLLOW NOTIFICATION: Sending notification from \(username) to \(toUserId)")

            // Create notification directly
            let notification = AppNotification(
                type: .follow,
                fromUserId: currentUserId,
                fromUsername: username,
                fromUserProfileImage: data["profileImageURL"] as? String,
                toUserId: toUserId,
                message: "\(username) requested friend"
            )

            do {
                let docRef = try db.collection("notifications").addDocument(from: notification)
                print("✅ FOLLOW: Notification saved with ID: \(docRef.documentID)")
            } catch {
                print("❌ FOLLOW: Failed to save notification - \(error)")
            }
        }
    }

    func sendFollowAcceptedNotification(toUserId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let error = error {
                print(
                    "❌ FOLLOW ACCEPTED NOTIFICATION: Failed to fetch username - \(error.localizedDescription)"
                )
                return
            }

            guard let data = snapshot?.data(),
                let username = data["username"] as? String
            else { return }

            // Create notification directly
            let notification = AppNotification(
                type: .followAccepted,
                fromUserId: currentUserId,
                fromUsername: username,
                fromUserProfileImage: data["profileImageURL"] as? String,
                toUserId: toUserId,
                message: "\(username) accepted your friend request"
            )

            do {
                try db.collection("notifications").addDocument(from: notification)
                print("✅ FOLLOW ACCEPTED: Notification saved")
            } catch {
                print("❌ FOLLOW ACCEPTED: Failed to save notification - \(error)")
            }
        }
    }

    // MARK: - Handle Timetable Share Notifications

    func sendTimetableShareRequest(toUserId: String, shareRequestId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                let data = snapshot?.data(),
                let username = data["username"] as? String
            else { return }

            self.sendNotification(
                type: .timetableShareRequest,
                toUserId: toUserId,
                message: "\(username) wants to share their timetable with you",
                timetableShareId: shareRequestId
            )
        }
    }

    func sendTimetableShareAccepted(toUserId: String, shareRequestId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                let data = snapshot?.data(),
                let username = data["username"] as? String
            else { return }

            self.sendNotification(
                type: .timetableShareAccepted,
                toUserId: toUserId,
                message: "\(username) accepted your timetable share request",
                timetableShareId: shareRequestId
            )
        }
    }

    func sendTimetableShareDeclined(toUserId: String, shareRequestId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                let data = snapshot?.data(),
                let username = data["username"] as? String
            else { return }

            self.sendNotification(
                type: .timetableShareDeclined,
                toUserId: toUserId,
                message: "\(username) declined your timetable share request",
                timetableShareId: shareRequestId
            )
        }
    }

    // MARK: - Post Notifications

    func sendPostLikeNotification(toUserId: String, postId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ POST LIKE NOTIFICATION: No current user")
            return
        }
        guard currentUserId != toUserId else {
            print("⚠️ POST LIKE NOTIFICATION: Not sending to self")
            return
        }

        print("🔔 POST LIKE NOTIFICATION: Attempting to send to \(toUserId)")

        let db = Firestore.firestore()

        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let error = error {
                print(
                    "❌ POST LIKE NOTIFICATION: Failed to fetch username - \(error.localizedDescription)"
                )
                return
            }

            guard let data = snapshot?.data(),
                let username = data["username"] as? String
            else {
                print("❌ POST LIKE NOTIFICATION: No username found for current user")
                return
            }

            print("✅ POST LIKE NOTIFICATION: Sending notification from \(username) to \(toUserId)")

            // Create notification directly
            let notification = AppNotification(
                type: .postLike,
                fromUserId: currentUserId,
                fromUsername: username,
                fromUserProfileImage: data["profileImageURL"] as? String,
                toUserId: toUserId,
                message: "\(username) liked your post",
                postId: postId
            )

            do {
                let docRef = try db.collection("notifications").addDocument(from: notification)
                print("✅ POST LIKE: Notification saved with ID: \(docRef.documentID)")
            } catch {
                print("❌ POST LIKE: Failed to save notification - \(error)")
            }
        }
    }

    func sendPostCommentNotification(toUserId: String, postId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ POST COMMENT NOTIFICATION: No current user")
            return
        }
        guard currentUserId != toUserId else {
            print("⚠️ POST COMMENT NOTIFICATION: Not sending to self")
            return
        }

        print("🔔 POST COMMENT NOTIFICATION: Attempting to send to \(toUserId)")

        let db = Firestore.firestore()

        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let error = error {
                print(
                    "❌ POST COMMENT NOTIFICATION: Failed to fetch username - \(error.localizedDescription)"
                )
                return
            }

            guard let data = snapshot?.data(),
                let username = data["username"] as? String
            else {
                print("❌ POST COMMENT NOTIFICATION: No username found for current user")
                return
            }

            print(
                "✅ POST COMMENT NOTIFICATION: Sending notification from \(username) to \(toUserId)")

            // Create notification directly
            let notification = AppNotification(
                type: .postComment,
                fromUserId: currentUserId,
                fromUsername: username,
                fromUserProfileImage: data["profileImageURL"] as? String,
                toUserId: toUserId,
                message: "\(username) commented on your post",
                postId: postId
            )

            do {
                let docRef = try db.collection("notifications").addDocument(from: notification)
                print("✅ POST COMMENT: Notification saved with ID: \(docRef.documentID)")
            } catch {
                print("❌ POST COMMENT: Failed to save notification - \(error)")
            }
        }
    }
    // MARK: - Event Share Notification

    func sendEventInviteNotification(
        toUserId: String,
        eventId: String,
        eventTitle: String
    ) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let username = data["username"] as? String
            else { return }

            self.sendNotification(
                type: .eventInvite,   // ⭐ 핵심 (enum!)
                toUserId: toUserId,
                message: "\(username) shared an event: \(eventTitle)",
                eventId: eventId
            )
        }
    }

}
