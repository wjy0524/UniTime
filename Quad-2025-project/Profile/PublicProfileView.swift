//
//  PublicProfileView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.

//
//  PublicProfileView.swift
//

import FirebaseAuth
import Kingfisher
import SwiftUI

struct PublicProfileView: View {
    let targetUid: String  // 🔥 보고 있는 상대 UID
    @StateObject var viewModel: ProfileViewModel
    @ObservedObject var friendsManager = FriendsManager.shared

    @Environment(\.colorScheme) var colorScheme

    @State private var selectedTab = 0
    @State private var showEdit = false
    @State private var isFriend = false
    @State private var hasPendingRequest = false
    @State private var requestSentByMe = false
    @State private var isProcessing = false

    // MARK: - Init
    init(targetUid: String) {
        self.targetUid = targetUid
        _viewModel = StateObject(wrappedValue: ProfileViewModel(uid: targetUid))
    }

    var myUid: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var friendButtonText: String {
        if isFriend {
            return "Friends"
        } else if hasPendingRequest && requestSentByMe {
            return "Request Sent"
        } else if hasPendingRequest && !requestSentByMe {
            return "Respond"
        } else {
            return "Add Friend"
        }
    }

    var friendButtonColor: Color {
        if isFriend {
            return .green
        } else if hasPendingRequest {
            return .orange
        } else {
            return Color("UTAustinOrange")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    profileHeader
                    userInfoSection

                    Picker("", selection: $selectedTab) {
                        Text("Posts").tag(0)
                        Text("Likes").tag(1)
                        Text("About").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    tabContent
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle(viewModel.username)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if myUid == targetUid {
                        // 내 프로필: Edit
                        Button {
                            showEdit = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color("UTAustinOrange"))
                        }

                    } else {
                        // 상대 프로필: Friend Actions
                        if isProcessing {
                            ProgressView()
                        } else if isFriend {
                            Menu {
                                Button(role: .destructive) {
                                    removeFriend()
                                } label: {
                                    Label("Remove Friend", systemImage: "person.fill.xmark")
                                }
                            } label: {
                                Text("Friends")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        } else if hasPendingRequest && !requestSentByMe {
                            NavigationLink(
                                destination: FriendRequestsListView(friendsManager: friendsManager)
                            ) {
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
                                handleFriendAction()
                            } label: {
                                Text(friendButtonText)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(friendButtonColor)
                                    .cornerRadius(8)
                            }
                            .disabled(hasPendingRequest && requestSentByMe)
                        }
                    }
                }
            }
            .task {
                await checkFriendshipStatus()
            }
            .sheet(isPresented: $showEdit) {
                ProfileEditView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Friend Actions

    func checkFriendshipStatus() async {
        isFriend = await friendsManager.isFriend(userId: targetUid)

        // Check for pending requests
        let sentRequest = friendsManager.sentRequests.first { $0.toUserId == targetUid }
        let receivedRequest = friendsManager.friendRequests.first { $0.fromUserId == targetUid }

        hasPendingRequest = sentRequest != nil || receivedRequest != nil
        requestSentByMe = sentRequest != nil
    }

    func handleFriendAction() {
        guard !isProcessing else { return }

        if hasPendingRequest && requestSentByMe {
            // Cancel request
            if let request = friendsManager.sentRequests.first(where: { $0.toUserId == targetUid })
            {
                isProcessing = true
                Task {
                    try? await friendsManager.cancelFriendRequest(request)
                    await checkFriendshipStatus()
                    isProcessing = false
                }
            }
        } else {
            // Send friend request
            isProcessing = true
            Task {
                do {
                    try await friendsManager.sendFriendRequest(
                        to: targetUid,
                        username: viewModel.username
                    )
                    await checkFriendshipStatus()
                    await viewModel.refreshStats()
                } catch {
                    print("Error sending friend request: \(error.localizedDescription)")
                }
                isProcessing = false
            }
        }
    }

    func removeFriend() {
        guard let friend = friendsManager.friends.first(where: { $0.friendId == targetUid }) else {
            return
        }

        isProcessing = true
        Task {
            try? await friendsManager.removeFriend(friend)
            await checkFriendshipStatus()
            await viewModel.refreshStats()
            isProcessing = false
        }
    }
}

extension PublicProfileView {
    var profileHeader: some View {
        VStack(spacing: 0) {

            Rectangle()
                .fill(Color("UTAustinOrange").opacity(colorScheme == .dark ? 0.32 : 0.18))
                .frame(height: 130)

            VStack {
                if let url = URL(string: viewModel.profileImageURL),
                    !viewModel.profileImageURL.isEmpty
                {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .offset(y: -55)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.9))
                        )
                        .offset(y: -55)
                }
            }
            .padding(.bottom, -40)
        }
    }
}

extension PublicProfileView {
    var userInfoSection: some View {
        VStack(spacing: 8) {

            Text(viewModel.username)
                .font(.title2.bold())

            if !viewModel.major.isEmpty {
                Text("\(viewModel.year) · \(viewModel.major)")
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.8))
            }

            HStack(spacing: 28) {
                VStack {
                    Text("\(viewModel.followersCount)")
                        .font(.headline)
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("\(viewModel.followingCount)")
                        .font(.headline)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 6)
        }
    }
}

struct ProfileCard: View {
    let title: String
    let subtitle: String?
    let icon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(.red)
                }
                Text(title)
                    .font(.headline)
                Spacer()
            }

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

extension PublicProfileView {

    var postsList: some View {
        UserPostsView(viewModel: viewModel)
    }

    var likesList: some View {
        UserLikedPostsView(viewModel: viewModel)
    }

    var aboutSectionCard: some View {
        ProfileCard(
            title: "About Me",
            subtitle: viewModel.bio.isEmpty ? "No bio added yet." : viewModel.bio,
            icon: "person.text.rectangle"
        )
    }

    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case 0:
            UserPostsView(viewModel: viewModel)
        case 1:
            UserLikedPostsView(viewModel: viewModel)
        case 2:
            ProfileAboutView(bio: viewModel.bio)
        default:
            EmptyView()
        }
    }
}
