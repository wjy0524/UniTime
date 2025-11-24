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
        startListening()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Fetch Notifications

    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        listener = db.collection("notifications")
            .whereField("toUserId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage =
                        "Failed to load notifications: \(error.localizedDescription)"
                    self.showingError = true
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.notifications = documents.compactMap { doc in
                    try? doc.data(as: AppNotification.self)
                }

                self.unreadCount = self.notifications.filter { !$0.isRead }.count
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
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // Fetch current user info
        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                let data = snapshot?.data(),
                let username = data["username"] as? String
            else { return }

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

            do {
                try self.db.collection("notifications").addDocument(from: notification)
            } catch {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Handle Follow Notification

    func sendFollowNotification(toUserId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                let data = snapshot?.data(),
                let username = data["username"] as? String
            else { return }

            self.sendNotification(
                type: .follow,
                toUserId: toUserId,
                message: "\(username) started following you"
            )
        }
    }

    func sendFollowAcceptedNotification(toUserId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                let data = snapshot?.data(),
                let username = data["username"] as? String
            else { return }

            self.sendNotification(
                type: .followAccepted,
                toUserId: toUserId,
                message: "\(username) accepted your follow request"
            )
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
}
