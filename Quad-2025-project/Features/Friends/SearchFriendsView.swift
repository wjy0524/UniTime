//
//  SearchFriendsView.swift
//  Quad-2025-project
//
//  View for searching and adding friends
//

import Kingfisher
import SwiftUI

struct SearchFriendsView: View {
    @ObservedObject var friendsManager: FriendsManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var lastSearchQuery = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchQuery, onCommit: performSearch)
                    .padding()
                    .onChange(of: searchQuery) { oldValue, newValue in
                        if !newValue.isEmpty {
                            performSearch()
                        } else {
                            friendsManager.searchResults = []
                        }
                    }

                // Results
                if friendsManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if friendsManager.searchResults.isEmpty && !searchQuery.isEmpty {
                    emptyResultsView
                } else if friendsManager.searchResults.isEmpty {
                    searchPromptView
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
                }
            }
        }
    }

    // MARK: - Search Prompt

    var searchPromptView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("Search for friends")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Enter a username to find people")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Results

    var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No users found")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Search Results List

    var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(friendsManager.searchResults) { result in
                    SearchResultRow(result: result, friendsManager: friendsManager)
                }
            }
            .padding()
        }
    }

    // MARK: - Perform Search

    func performSearch() {
        isSearching = true
        lastSearchQuery = searchQuery
        Task {
            await friendsManager.searchUsers(query: searchQuery)
            isSearching = false
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    var onCommit: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search username", text: $text, onCommit: onCommit)
                .textFieldStyle(.plain)
                .autocapitalization(.none)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: FriendSearchResult
    @ObservedObject var friendsManager: FriendsManager
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageURL = result.profileImageURL, !imageURL.isEmpty,
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
                Text(result.username)
                    .font(.headline)

                if let major = result.major, let year = result.year {
                    Text("\(year) · \(major)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let major = result.major {
                    Text(major)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Action Button
            actionButton
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    @ViewBuilder
    var actionButton: some View {
        if isLoading {
            ProgressView()
        } else if result.isFriend {
            Text("Friends")
                .font(.subheadline.bold())
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
        } else if result.hasPendingRequest && result.requestSentByMe {
            Text("Pending")
                .font(.subheadline.bold())
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
        } else if result.hasPendingRequest && !result.requestSentByMe {
            NavigationLink(destination: FriendRequestsListView(friendsManager: friendsManager)) {
                Text("Respond")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        } else {
            Button {
                sendFriendRequest()
            } label: {
                Text("Add Friend")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
    }

    func sendFriendRequest() {
        isLoading = true
        Task {
            do {
                try await friendsManager.sendFriendRequest(
                    to: result.id,
                    username: result.username
                )
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
}

#Preview {
    SearchFriendsView(friendsManager: FriendsManager.shared)
}
