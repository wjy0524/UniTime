//
//  SearchStudyFriendsView.swift
//  Quad-2025-project
//
//  Search view for finding and adding study friends
//

import SwiftUI

struct SearchStudyFriendsView: View {
    @ObservedObject var friendsManager: StudyFriendsManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var searchQuery = ""
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search by username...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .onChange(of: searchQuery) { oldValue, newValue in
                            if !newValue.isEmpty {
                                isSearching = true
                                Task {
                                    await friendsManager.searchUsers(query: newValue)
                                    isSearching = false
                                }
                            } else {
                                friendsManager.searchResults = []
                            }
                        }

                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            friendsManager.searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
                .cornerRadius(10)
                .padding()

                Divider()

                // Results
                if isSearching || friendsManager.isLoading {
                    loadingView
                } else if searchQuery.isEmpty {
                    instructionsView
                } else if friendsManager.searchResults.isEmpty {
                    emptyResultsView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Find Friends")
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

    // MARK: - Loading View

    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Instructions View

    var instructionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(Color("UTAustinOrange").opacity(0.5))

            Text("Search for Study Friends")
                .font(.title2)
                .bold()

            Text("Enter a username to find friends and track their study time together!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Results View

    var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Results")
                .font(.title2)
                .bold()

            Text("No users found matching '\(searchQuery)'")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Search Results List

    var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(friendsManager.searchResults) { result in
                    SearchResultCard(result: result, friendsManager: friendsManager)
                }
            }
            .padding()
        }
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let result: FriendSearchResult
    @ObservedObject var friendsManager: StudyFriendsManager
    @Environment(\.colorScheme) var colorScheme
    @State private var isProcessing = false

    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color("UTAustinOrange").opacity(0.7),
                            Color.orange.opacity(0.5),
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

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.username)
                    .font(.headline)

                if let major = result.major {
                    Text(major)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let year = result.year {
                    Text(year)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Action Button
            if result.isFriend {
                // Already friends
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Friends")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

            } else if result.hasPendingRequest {
                if result.requestSentByMe {
                    // Request sent by me - show pending
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("Pending")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                } else {
                    // Request sent to me - show in requests tab
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.purple)
                        Text("Respond")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }

            } else {
                // Can send friend request
                Button {
                    isProcessing = true
                    Task {
                        await friendsManager.sendFriendRequest(
                            toUserId: result.id,
                            toUsername: result.username
                        )
                        isProcessing = false
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 80)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "person.badge.plus")
                            Text("Add")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("UTAustinOrange"))
                        .cornerRadius(8)
                    }
                }
                .disabled(isProcessing)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
        .cornerRadius(12)
    }
}

#Preview {
    SearchStudyFriendsView(friendsManager: StudyFriendsManager())
}
