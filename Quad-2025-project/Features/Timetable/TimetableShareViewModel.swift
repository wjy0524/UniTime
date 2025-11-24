//
//  TimetableShareViewModel.swift
//  Quad-2025-project
//
//  Created on Timetable Sharing Feature Implementation
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

class TimetableShareViewModel: ObservableObject {
    @Published var shareRequests: [TimetableShareRequest] = []
    @Published var sentRequests: [TimetableShareRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    @Published var successMessage: String?
    @Published var showingSuccess: Bool = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var sentRequestsListener: ListenerRegistration?

    static let shared = TimetableShareViewModel()

    init() {
        startListening()
    }

    deinit {
        listener?.remove()
        sentRequestsListener?.remove()
    }

    // MARK: - Fetch Share Requests

    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Listen to incoming share requests
        listener = db.collection("timetableShareRequests")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: TimetableShareRequest.ShareStatus.pending.rawValue)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage =
                        "Failed to load share requests: \(error.localizedDescription)"
                    self.showingError = true
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.shareRequests = documents.compactMap { doc in
                    try? doc.data(as: TimetableShareRequest.self)
                }
            }

        // Listen to sent share requests
        sentRequestsListener = db.collection("timetableShareRequests")
            .whereField("fromUserId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Failed to load sent requests: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.sentRequests = documents.compactMap { doc in
                    try? doc.data(as: TimetableShareRequest.self)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        sentRequestsListener?.remove()
        sentRequestsListener = nil
    }

    // MARK: - Send Share Request

    func sendShareRequest(
        toUserId: String,
        toUsername: String,
        courses: [TimetableCourse],
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion?(false)
            return
        }

        isLoading = true

        // Fetch current user info
        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion?(false)
                return
            }

            if let error = error {
                self.errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                self.showingError = true
                self.isLoading = false
                completion?(false)
                return
            }

            guard let data = snapshot?.data(),
                let username = data["username"] as? String
            else {
                self.errorMessage = "Failed to retrieve username"
                self.showingError = true
                self.isLoading = false
                completion?(false)
                return
            }

            let profileImageURL = data["profileImageURL"] as? String

            let shareRequest = TimetableShareRequest(
                fromUserId: currentUserId,
                fromUsername: username,
                fromUserProfileImage: profileImageURL,
                toUserId: toUserId,
                toUsername: toUsername,
                timetableCourses: courses
            )

            do {
                let docRef = try self.db.collection("timetableShareRequests").addDocument(
                    from: shareRequest)

                // Send notification
                let notificationVM = NotificationViewModel()
                notificationVM.sendTimetableShareRequest(
                    toUserId: toUserId,
                    shareRequestId: docRef.documentID
                )

                self.successMessage = "Share request sent to \(toUsername)!"
                self.showingSuccess = true
                self.isLoading = false
                completion?(true)

            } catch {
                self.errorMessage = "Failed to send share request: \(error.localizedDescription)"
                self.showingError = true
                self.isLoading = false
                completion?(false)
            }
        }
    }

    // MARK: - Accept Share Request

    func acceptShareRequest(_ requestId: String) {
        guard let request = shareRequests.first(where: { $0.id == requestId }) else { return }

        isLoading = true

        db.collection("timetableShareRequests").document(requestId).updateData([
            "status": TimetableShareRequest.ShareStatus.accepted.rawValue
        ]) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = "Failed to accept request: \(error.localizedDescription)"
                self.showingError = true
                self.isLoading = false
                return
            }

            // Send acceptance notification
            let notificationVM = NotificationViewModel()
            notificationVM.sendTimetableShareAccepted(
                toUserId: request.fromUserId,
                shareRequestId: requestId
            )

            self.successMessage =
                "Timetable shared! You can now view \(request.fromUsername)'s schedule."
            self.showingSuccess = true
            self.isLoading = false
        }
    }

    // MARK: - Decline Share Request

    func declineShareRequest(_ requestId: String) {
        guard let request = shareRequests.first(where: { $0.id == requestId }) else { return }

        isLoading = true

        db.collection("timetableShareRequests").document(requestId).updateData([
            "status": TimetableShareRequest.ShareStatus.declined.rawValue
        ]) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = "Failed to decline request: \(error.localizedDescription)"
                self.showingError = true
                self.isLoading = false
                return
            }

            // Send decline notification
            let notificationVM = NotificationViewModel()
            notificationVM.sendTimetableShareDeclined(
                toUserId: request.fromUserId,
                shareRequestId: requestId
            )

            self.successMessage = "Share request declined"
            self.showingSuccess = true
            self.isLoading = false
        }
    }

    // MARK: - Delete Share Request

    func deleteShareRequest(_ requestId: String) {
        db.collection("timetableShareRequests").document(requestId).delete { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to delete request: \(error.localizedDescription)"
                self?.showingError = true
            }
        }
    }

    // MARK: - Get Shared Timetables

    func getSharedTimetables(completion: @escaping ([TimetableShareRequest]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("timetableShareRequests")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: TimetableShareRequest.ShareStatus.accepted.rawValue)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to fetch shared timetables: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let requests =
                    snapshot?.documents.compactMap { doc in
                        try? doc.data(as: TimetableShareRequest.self)
                    } ?? []

                completion(requests)
            }
    }

    // MARK: - Check if already sent request

    func hasActiveSentRequest(toUserId: String) -> Bool {
        return sentRequests.contains { request in
            request.toUserId == toUserId && request.status == .pending
        }
    }
}
