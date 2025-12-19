//
//  FriendRequestsListView.swift
//  Quad-2025-project
//
//  View for managing incoming and outgoing friend requests
//

import Kingfisher
import SwiftUI

struct FriendRequestsListView: View {
    @ObservedObject var friendsManager: FriendsManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Requests", selection: $selectedTab) {
                    Text("Received (\(friendsManager.friendRequests.count))").tag(0)
                    Text("Sent (\(friendsManager.sentRequests.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                if selectedTab == 0 {
                    receivedRequestsList
                } else {
                    sentRequestsList
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Received Requests

    var receivedRequestsList: some View {
        Group {
            if friendsManager.friendRequests.isEmpty {
                emptyReceivedView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(friendsManager.friendRequests) { request in
                            ReceivedRequestRow(request: request, friendsManager: friendsManager)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    var emptyReceivedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.open")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No pending requests")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("You'll see friend requests here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sent Requests

    var sentRequestsList: some View {
        Group {
            if friendsManager.sentRequests.isEmpty {
                emptySentView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(friendsManager.sentRequests) { request in
                            SentRequestRow(request: request, friendsManager: friendsManager)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    var emptySentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "paperplane")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No sent requests")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Requests you send will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Received Request Row

struct ReceivedRequestRow: View {
    let request: FriendRequest
    @ObservedObject var friendsManager: FriendsManager
    @State private var isProcessing = false

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageURL = request.fromProfileImage, !imageURL.isEmpty,
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

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromUsername)
                    .font(.headline)

                Text("Sent \(formatDate(request.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let message = request.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Action Buttons
            if isProcessing {
                ProgressView()
            } else {
                HStack(spacing: 8) {
                    Button {
                        acceptRequest()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.green))
                    }

                    Button {
                        declineRequest()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.red))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    func acceptRequest() {
        isProcessing = true
        Task {
            do {
                print("🔵 Attempting to accept request from: \(request.fromUsername)")
                try await friendsManager.acceptFriendRequest(request)
                print("✅ Accept completed successfully")
                isProcessing = false
            } catch {
                print("❌ ERROR accepting request: \(error)")
                print("❌ ERROR localizedDescription: \(error.localizedDescription)")
                isProcessing = false
            }
        }
    }

    func declineRequest() {
        isProcessing = true
        Task {
            try await friendsManager.declineFriendRequest(request)
            isProcessing = false
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sent Request Row

struct SentRequestRow: View {
    let request: FriendRequest
    @ObservedObject var friendsManager: FriendsManager
    @State private var isProcessing = false
    @State private var showCancelConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageURL = request.toProfileImage, !imageURL.isEmpty,
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

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(request.toUsername)
                    .font(.headline)

                Text("Sent \(formatDate(request.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Pending...")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Spacer()

            // Cancel Button
            if isProcessing {
                ProgressView()
            } else {
                Button {
                    showCancelConfirmation = true
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
        .confirmationDialog("Cancel friend request?", isPresented: $showCancelConfirmation) {
            Button("Cancel Request", role: .destructive) {
                cancelRequest()
            }
            Button("Keep Request", role: .cancel) {}
        }
    }

    func cancelRequest() {
        isProcessing = true
        Task {
            try await friendsManager.cancelFriendRequest(request)
            isProcessing = false
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    FriendRequestsListView(friendsManager: FriendsManager.shared)
}
