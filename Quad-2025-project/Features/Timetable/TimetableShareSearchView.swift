//
//  TimetableShareSearchView.swift
//  Quad-2025-project
//

//  TimetableShareSearchView.swift
//  Quad-2025-project
//

import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUI

struct TimetableShareSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var timetableViewModel: TimetableViewModel
    @StateObject private var friendService = FriendService.shared
    @StateObject private var shareViewModel = TimetableShareViewModel.shared

    @State private var friends: [Friend] = []   // 🔥 UI용 친구 리스트
    @State private var isSharing = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if friends.isEmpty {
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
            .task {
                await friendService.loadAll()
                friends = await friendService.fetchFriendUsers()   // ✅ 핵심
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

            Text("Add friends to share your timetable with them")
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
            ForEach(friends) { friend in
                FriendRowForSharing(
                    friend: friend,
                    isSharing: isSharing
                ) {
                    shareTimetable(with: friend)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Share Logic

    func shareTimetable(with friend: Friend) {
        guard let myUid = Auth.auth().currentUser?.uid else {
            shareViewModel.errorMessage = "Not authenticated"
            shareViewModel.showingError = true
            return
        }

        isSharing = true

        Task {
            do {
                let userDoc = try await db
                    .collection("users")
                    .document(myUid)
                    .getDocument()

                guard let data = userDoc.data(),
                      let myUsername = data["username"] as? String else {
                    throw NSError(domain: "Share", code: 1)
                }

                let myProfileImage = data["profileImageURL"] as? String

                let request = TimetableShareRequest(
                    fromUserId: myUid,
                    fromUsername: myUsername,
                    fromUserProfileImage: myProfileImage,
                    toUserId: friend.uid,
                    toUsername: friend.username,
                    timestamp: Date(),
                    status: .pending,
                    timetableCourses: timetableViewModel.courses
                )

                try db
                    .collection("timetableShareRequests")
                    .addDocument(from: request)

                await MainActor.run {
                    shareViewModel.successMessage =
                        "Timetable shared with \(friend.username)"
                    shareViewModel.showingSuccess = true
                    isSharing = false
                }

            } catch {
                await MainActor.run {
                    shareViewModel.errorMessage = error.localizedDescription
                    shareViewModel.showingError = true
                    isSharing = false
                }
            }
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - Friend Row
////////////////////////////////////////////////////////////

struct FriendRowForSharing: View {
    let friend: Friend
    let isSharing: Bool
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let imageURL = friend.profileImageURL,
               let url = URL(string: imageURL) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }

            Text(friend.username)
                .font(.headline)

            Spacer()

            if isSharing {
                ProgressView()
            } else {
                Button("Share") {
                    onShare()
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 6)
    }
}
