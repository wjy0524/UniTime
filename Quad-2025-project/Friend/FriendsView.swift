//
//  FriendsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/23/26.

import SwiftUI

struct FriendsView: View {
    let uid: String

    @StateObject private var viewModel: FriendsViewModel

    init(uid: String) {
        self.uid = uid
        _viewModel = StateObject(
            wrappedValue: FriendsViewModel(uid: uid)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading friends...")
                } else if viewModel.friends.isEmpty {
                    emptyView
                } else {
                    friendsList
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Friends List

    var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.friends, id: \.self) { friendUid in
                    NavigationLink {
                        PublicProfileView(targetUid: friendUid)
                    } label: {
                        FriendRow(
                            uid: friendUid,
                            isMyFriendsList: uid == viewModel.myUid
                        )
                    }
                    .buttonStyle(PressableRowStyle())
                }
            }
            .padding()
        }
        
    }

    // MARK: - Empty State

    var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.6))

            Text("No friends yet")
                .font(.title3.bold())

            Text("Find classmates and start connecting")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                SearchUserView()
            } label: {
                Text("Find Friends")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color("UTAustinOrange"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(.top, 80)
    }
}

////////////////////////////////////////////////////////////
// MARK: - Friend Row
////////////////////////////////////////////////////////////

struct FriendRow: View {
    let uid: String
    let isMyFriendsList: Bool

    @StateObject private var profileVM: ProfileViewModel
    @StateObject private var friendService = FriendService.shared
    @State private var showRemoveConfirm = false

    init(uid: String, isMyFriendsList: Bool) {
        self.uid = uid
        self.isMyFriendsList = isMyFriendsList
        _profileVM = StateObject(
            wrappedValue: ProfileViewModel(uid: uid)
        )
    }

    var body: some View {
        HStack(spacing: 14) {

            // Avatar
            if let url = URL(string: profileVM.profileImageURL),
               !profileVM.profileImageURL.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }

            // Name + subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(profileVM.username)
                    .font(.headline)

                let subtitle: String = {
                    let major = profileVM.major
                    let year = profileVM.year

                    if !major.isEmpty && !year.isEmpty {
                        return "\(major) · \(year)"
                    } else if !major.isEmpty {
                        return major
                    } else if !year.isEmpty {
                        return year
                    } else {
                        return ""
                    }
                }()

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Remove friend menu (내 친구 목록에서만)
            if isMyFriendsList {
                Menu {
                    Button(role: .destructive) {
                        showRemoveConfirm = true
                    } label: {
                        Label("Remove Friend", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
        .confirmationDialog(
            "Remove friend?",
            isPresented: $showRemoveConfirm
        ) {
            Button("Remove Friend", role: .destructive) {
                Task {
                    await friendService.removeFriend(uid: uid)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - Press Animation
////////////////////////////////////////////////////////////

struct PressableRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
