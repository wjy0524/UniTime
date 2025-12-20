//
//  FriendsView.swift
//  Quad-2025-project
//
//  Main friends view showing friends list and requests
//

import Kingfisher
import SwiftUI

struct FriendsView: View {
    @ObservedObject private var friendsManager = FriendsManager.shared
    @State private var showSearchSheet = false
    @State private var showRequestsSheet = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats
                    statsSection

                    // Actions
                    actionButtons

                    // Friends List
                    friendsListSection
                }
                .padding()
            }
            .navigationTitle("Friends")
            .onAppear {
                friendsManager.startListening()
            }
            .sheet(isPresented: $showSearchSheet) {
                SearchFriendsView(friendsManager: friendsManager)
            }
            .sheet(isPresented: $showRequestsSheet) {
                FriendRequestsListView(friendsManager: friendsManager)
            }
        }
    }

    // MARK: - Stats Section

    var statsSection: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Friends",
                count: friendsManager.friends.count,
                icon: "person.2.fill",
                color: .blue
            )

            StatCard(
                title: "Requests",
                count: friendsManager.friendRequests.count,
                icon: "envelope.fill",
                color: .orange
            )
        }
    }

    // MARK: - Action Buttons

    var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showSearchSheet = true
            } label: {
                Label("Find Friends", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Button {
                showRequestsSheet = true
            } label: {
                Label("Requests", systemImage: "envelope.badge")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        friendsManager.friendRequests.isEmpty
                            ? Color.gray.opacity(0.3) : Color.orange
                    )
                    .foregroundColor(friendsManager.friendRequests.isEmpty ? .secondary : .white)
                    .cornerRadius(12)
                    .overlay(
                        friendsManager.friendRequests.count > 0
                            ? Text("\(friendsManager.friendRequests.count)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Circle().fill(Color.red))
                                .offset(x: 8, y: -8)
                            : nil,
                        alignment: .topTrailing
                    )
            }
        }
    }

    // MARK: - Friends List

    var friendsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Friends")
                .font(.headline)
                .padding(.horizontal, 4)

            if friendsManager.friends.isEmpty {
                emptyFriendsView
            } else {
                ForEach(friendsManager.friends) { friend in
                    FriendRowView(friend: friend, friendsManager: friendsManager)
                }
            }
        }
    }

    var emptyFriendsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No friends yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Find and add friends to connect with them!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showSearchSheet = true
            } label: {
                Text("Find Friends")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)

            Text("\(count)")
                .font(.title.bold())

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Friend Row View

struct FriendRowView: View {
    let friend: Friend
    @ObservedObject var friendsManager: FriendsManager
    @State private var showOptions = false
    @State private var showProfile = false
    @Environment(\.colorScheme) var colorScheme

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

            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.friendUsername)
                    .font(.headline)

                if let acceptedAt = friend.acceptedAt {
                    Text("Friends since \(formatDate(acceptedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // More Options Button
            Button {
                showOptions = true
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Circle().fill(Color(.systemGray6)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
        .confirmationDialog("Friend Options", isPresented: $showOptions) {
            Button("View Profile") {
                showProfile = true
            }

            Button("Remove Friend", role: .destructive) {
                Task {
                    try await friendsManager.removeFriend(friend)
                }
            }

            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                PublicProfileView(targetUid: friend.friendId)
            }
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    FriendsView()
}
