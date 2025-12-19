//
//  TimetableShareSearchView.swift
//  Quad-2025-project
//
//  Share timetable with friends from unified friends list
//

import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUI

struct TimetableShareSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shareViewModel = TimetableShareViewModel.shared
    @ObservedObject var timetableViewModel: TimetableViewModel
    @ObservedObject private var friendsManager = FriendsManager.shared

    @State private var selectedFriend: Friend?
    @State private var isSharing: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if friendsManager.friends.isEmpty {
                    emptyFriendsView
                } else {
                    friendsList
                }
            }
            .navigationTitle("Share with Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                friendsManager.startListening()
            }
            .alert("Success", isPresented: $shareViewModel.showingSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(shareViewModel.successMessage ?? "Timetable shared successfully!")
            }
            .alert("Error", isPresented: $shareViewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(shareViewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Empty State

    var emptyFriendsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Friends Yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Add friends from the main Friends page to share your timetable with them")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Friends List

    var friendsList: some View {
        List {
            ForEach(friendsManager.friends) { friend in
                FriendRowForSharing(
                    friend: friend,
                    isSharing: isSharing,
                    onShare: {
                        shareTimetableWith(friend: friend)
                    }
                )
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Share Action

    func shareTimetableWith(friend: Friend) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            shareViewModel.errorMessage = "Not authenticated"
            shareViewModel.showingError = true
            return
        }

        isSharing = true

        Task {
            do {
                // Get current user info
                let userDoc = try await db.collection("users").document(currentUserId).getDocument()
                guard let userData = userDoc.data(),
                    let currentUsername = userData["username"] as? String
                else {
                    throw NSError(
                        domain: "TimetableShare", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Could not fetch user data"])
                }

                let currentProfileImage = userData["profileImageURL"] as? String

                // Create share request
                let shareRequest = TimetableShareRequest(
                    fromUserId: currentUserId,
                    fromUsername: currentUsername,
                    fromUserProfileImage: currentProfileImage,
                    toUserId: friend.friendId,
                    toUsername: friend.friendUsername,
                    timestamp: Date(),
                    status: .pending,
                    timetableCourses: timetableViewModel.courses
                )

                // Save to Firestore
                try db.collection("timetableShareRequests").addDocument(from: shareRequest)

                await MainActor.run {
                    shareViewModel.successMessage = "Timetable shared with \(friend.friendUsername)"
                    shareViewModel.showingSuccess = true
                    isSharing = false
                }

                // Send notification
                let notificationVM = NotificationViewModel()
                if let requestId = shareRequest.id {
                    notificationVM.sendTimetableShareRequest(
                        toUserId: friend.friendId, shareRequestId: requestId)
                }

            } catch {
                await MainActor.run {
                    shareViewModel.errorMessage = "Failed to share: \(error.localizedDescription)"
                    shareViewModel.showingError = true
                    isSharing = false
                }
            }
        }
    }

    private let db = Firestore.firestore()
}

// MARK: - Friend Row for Sharing

struct FriendRowForSharing: View {
    let friend: Friend
    let isSharing: Bool
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageURL = friend.friendProfileImage, !imageURL.isEmpty,
                let url = URL(string: imageURL)
            {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.friendUsername)
                    .font(.headline)

                Text("Friend")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSharing {
                ProgressView()
            } else {
                Button {
                    onShare()
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Share")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
