//
//  FriendRequestsView.swift
//  Quad-2025-project
//
//  View for managing incoming and outgoing friend requests
//

import SwiftUI

struct FriendRequestsView: View {
    @ObservedObject var friendsManager: StudyFriendsManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Requests", selection: $selectedTab) {
                    Text("Received (\(friendsManager.friendRequests.count))").tag(0)
                    Text("Sent (\(friendsManager.sentRequests.filter { $0.status == .pending }.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

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
                    .foregroundColor(Color("UTAustinOrange"))
                }
            }
        }
    }

    // MARK: - Received Requests

    var receivedRequestsList: some View {
        Group {
            if friendsManager.friendRequests.isEmpty {
                emptyReceivedState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(friendsManager.friendRequests) { request in
                            ReceivedRequestCard(request: request, friendsManager: friendsManager)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    var emptyReceivedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.open")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Friend Requests")
                .font(.title2)
                .bold()

            Text("You don't have any pending friend requests.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Sent Requests

    var sentRequestsList: some View {
        Group {
            let pendingRequests = friendsManager.sentRequests.filter { $0.status == .pending }

            if pendingRequests.isEmpty {
                emptySentState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(pendingRequests) { request in
                            SentRequestCard(request: request, friendsManager: friendsManager)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    var emptySentState: some View {
        VStack(spacing: 16) {
            Image(systemName: "paperplane")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Sent Requests")
                .font(.title2)
                .bold()

            Text("You haven't sent any friend requests yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Received Request Card

struct ReceivedRequestCard: View {
    let request: FriendRequest
    @ObservedObject var friendsManager: StudyFriendsManager
    @Environment(\.colorScheme) var colorScheme
    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("UTAustinOrange").opacity(0.7),
                                Color.orange.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.fromUsername)
                        .font(.headline)

                    Text(formatDate(request.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Message (if any)
            if let message = request.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.5 : 0.8))
                    .cornerRadius(8)
            }

            // Action Buttons
            if isProcessing {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 12) {
                    Button {
                        isProcessing = true
                        Task {
                            await friendsManager.acceptFriendRequest(request: request)
                            isProcessing = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button {
                        isProcessing = true
                        Task {
                            await friendsManager.declineFriendRequest(request: request)
                            isProcessing = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Decline")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
        .cornerRadius(12)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sent Request Card

struct SentRequestCard: View {
    let request: FriendRequest
    @ObservedObject var friendsManager: StudyFriendsManager
    @Environment(\.colorScheme) var colorScheme
    @State private var isProcessing = false
    @State private var showCancelConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.7),
                                Color.purple.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.toUsername)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("Pending")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)

                    Text(formatDate(request.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Cancel Button
                Button {
                    showCancelConfirmation = true
                } label: {
                    Text("Cancel")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Message (if any)
            if let message = request.message, !message.isEmpty {
                Text("Message: \(message)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
        .cornerRadius(12)
        .confirmationDialog("Cancel Friend Request?", isPresented: $showCancelConfirmation) {
            Button("Cancel Request", role: .destructive) {
                guard let requestId = request.id else { return }
                Task {
                    await friendsManager.cancelFriendRequest(requestId: requestId)
                }
            }
            Button("Keep Request", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel the friend request to \(request.toUsername)?")
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    FriendRequestsView(friendsManager: StudyFriendsManager())
}
