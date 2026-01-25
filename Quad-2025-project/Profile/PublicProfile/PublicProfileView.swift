
//
//  PublicProfileView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import Kingfisher
import SwiftUI

struct PublicProfileView: View {
    let targetUid: String

    @StateObject private var viewModel: ProfileViewModel
    @StateObject private var friendService = FriendService.shared

    @State private var selectedTab = 0
    @State private var showUnfriendConfirm = false

    init(targetUid: String) {
        self.targetUid = targetUid
        _viewModel = StateObject(
            wrappedValue: ProfileViewModel(uid: targetUid)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    userInfoSection
                    tabPicker
                    tabContent
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.username)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.myUid == targetUid {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .task {
                await friendService.loadAll()
            }
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - Friend Status
////////////////////////////////////////////////////////////

extension PublicProfileView {
    var friendStatus: FriendStatus {
        friendService.status(with: targetUid)
    }
}

////////////////////////////////////////////////////////////
// MARK: - Header
////////////////////////////////////////////////////////////

extension PublicProfileView {
    var profileHeader: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color("UTAustinOrange").opacity(0.18))
                .frame(height: 120)

            if let url = URL(string: viewModel.profileImageURL),
               !viewModel.profileImageURL.isEmpty {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 108, height: 108)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(.white, lineWidth: 3)
                    )
                    .offset(y: -54)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 108, height: 108)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 42))
                            .foregroundColor(.white)
                    )
                    .offset(y: -54)
            }
        }
        .padding(.bottom, -36)
    }
}

////////////////////////////////////////////////////////////
// MARK: - User Info + Friend Button
////////////////////////////////////////////////////////////

extension PublicProfileView {
    var userInfoSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.username)
                .font(.title3.bold())

            if !viewModel.major.isEmpty {
                Text("\(viewModel.year) · \(viewModel.major)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // ✅ Friends Count 표시
            Text("\(viewModel.friendsCount) Friends")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Friends 버튼
            NavigationLink {
                FriendsView(uid: targetUid)
            } label: {
                Text("View Friends")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 4)

            // 친구 버튼은 상대 프로필에서만
            if viewModel.myUid != targetUid {
                friendButton
            }
        }
        .padding(.horizontal)
    }


    @ViewBuilder
    var friendButton: some View {
        switch friendStatus {

        case .none:
            actionButton(
                "Add Friend",
                color: Color("UTAustinOrange")
            ) {
                Task {
                    await friendService.sendRequest(to: targetUid)
                    await friendService.loadAll() // 🔥 상태 즉시 반영
                }
            }

        case .sent:
            actionButton(
                "Request Sent",
                color: Color(.systemGray5),
                textColor: .primary
            ) {
                Task {
                    await friendService.cancelRequest(to: targetUid)
                    await friendService.loadAll() // 🔥
                }
            }


        case .received:
            actionButton(
                "Accept Friend Request",
                color: .green
            ) {
                Task {
                    await friendService.acceptRequest(from: targetUid)

                    // 🔥 추가
                    await viewModel.fetchFriendsCount(for: targetUid)
                    await viewModel.fetchFriendsCount(for: viewModel.myUid)
                }
            }

        case .friends:
            actionButton(
                "Friends ✓",
                color: Color(.systemGray5),
                textColor: .primary
            ) {
                showUnfriendConfirm = true
            }
            .confirmationDialog(
                "Remove friend?",
                isPresented: $showUnfriendConfirm
            ) {
                Button("Remove Friend", role: .destructive) {
                    Task {
                        await friendService.removeFriend(uid: targetUid)

                        // 🔥 친구 수 즉시 갱신
                        await viewModel.fetchFriendsCount(for: targetUid)
                        await viewModel.fetchFriendsCount(for: viewModel.myUid)
                    }
                }

                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Button Helpers

    func actionButton(
        _ title: String,
        color: Color,
        textColor: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color)
                .foregroundColor(textColor)
                .cornerRadius(10)
        }
    }

    func disabledButton(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .foregroundColor(.secondary)
            .cornerRadius(10)
    }
}

////////////////////////////////////////////////////////////
// MARK: - Tabs
////////////////////////////////////////////////////////////

extension PublicProfileView {
    var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            Text("Posts").tag(0)
            Text("Likes").tag(1)
            Text("About").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case 0:
            UserPostsView(viewModel: viewModel)

        case 1:
            UserLikedPostsView(viewModel: viewModel)

        case 2:
            Text(
                viewModel.bio.isEmpty
                ? "No bio added yet."
                : viewModel.bio
            )
            .foregroundColor(.secondary)
            .padding(.top, 12)

        default:
            EmptyView()
        }
    }
}
