//
//  TimetableShareSearchView.swift
//  Quad-2025-project
//
//  Created on Timetable Sharing Feature Implementation
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct TimetableShareSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shareViewModel = TimetableShareViewModel.shared
    @ObservedObject var timetableViewModel: TimetableViewModel

    @State private var searchText: String = ""
    @State private var searchResults: [UserSearchResult] = []
    @State private var isSearching: Bool = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if isSearching {
                    ProgressView()
                        .padding()
                } else if searchText.isEmpty {
                    emptySearchView
                } else if searchResults.isEmpty {
                    noResultsView
                } else {
                    userList
                }
            }
            .navigationTitle("Share Timetable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $shareViewModel.showingSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(shareViewModel.successMessage ?? "")
            }
            .alert("Error", isPresented: $shareViewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(shareViewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Search Bar

    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search users by username...", text: $searchText)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .onChange(of: searchText) {
                    performSearch(query: searchText)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }

    // MARK: - Empty Search View

    var emptySearchView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Search for Users")
                .font(.title2)
                .bold()

            Text("Find friends to share your timetable with")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - No Results View

    var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Users Found")
                .font(.title2)
                .bold()

            Text("Try searching with a different username")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - User List

    var userList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults) { user in
                    UserSearchRow(
                        user: user,
                        alreadySent: shareViewModel.hasActiveSentRequest(toUserId: user.uid),
                        onShare: {
                            shareWithUser(user)
                        }
                    )

                    Divider()
                        .padding(.leading, 70)
                }
            }
        }
    }

    // MARK: - Search Logic

    func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        isSearching = true

        let searchText = query.lowercased()

        db.collection("users")
            .whereField("username_lower", isGreaterThanOrEqualTo: searchText)
            .whereField("username_lower", isLessThanOrEqualTo: searchText + "~")
            .limit(to: 20)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isSearching = false

                    if let error = error {
                        print("Search error: \(error.localizedDescription)")
                        return
                    }

                    guard let documents = snapshot?.documents else { return }

                    searchResults = documents.compactMap { doc in
                        let data = doc.data()
                        guard let username = data["username"] as? String,
                            let uid = data["uid"] as? String,
                            uid != currentUserId
                        else { return nil }

                        return UserSearchResult(
                            uid: uid,
                            username: username,
                            fullName: data["fullName"] as? String,
                            profileImageURL: data["profileImageURL"] as? String
                        )
                    }
                }
            }
    }

    // MARK: - Share with User

    func shareWithUser(_ user: UserSearchResult) {
        guard !timetableViewModel.courses.isEmpty else {
            shareViewModel.errorMessage = "You have no courses to share"
            shareViewModel.showingError = true
            return
        }

        shareViewModel.sendShareRequest(
            toUserId: user.uid,
            toUsername: user.username,
            courses: timetableViewModel.courses
        ) { success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - User Search Result Model

struct UserSearchResult: Identifiable {
    let uid: String
    let username: String
    let fullName: String?
    let profileImageURL: String?

    var id: String { uid }
}

// MARK: - User Search Row

struct UserSearchRow: View {
    let user: UserSearchResult
    let alreadySent: Bool
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(user.username.prefix(1).uppercased()))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let fullName = user.fullName {
                    Text(fullName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 공유 키
            if alreadySent {
                Text("Sent")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            } else {
                Button(action: onShare) {
                    Text("Share")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

struct TimetableShareSearchView_Previews: PreviewProvider {
    static var previews: some View {
        TimetableShareSearchView(timetableViewModel: TimetableViewModel())
    }
}
