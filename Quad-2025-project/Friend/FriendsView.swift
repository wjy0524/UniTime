//
//  FriendsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/23/26.
//

//
//  FriendsView.swift
//  Quad-2025-project
//

import SwiftUI
import Kingfisher
import FirebaseFirestore

struct FriendsView: View {
    let uid: String   // 👈 이 사람의 친구 목록을 보여줌

    @StateObject private var friendService = FriendService.shared
    @State private var friends: [String] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading friends...")
                } else if friends.isEmpty {
                    emptyView
                } else {
                    friendsList
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadFriends()
            }
        }
    }

    // MARK: - Friends List

    var friendsList: some View {
        List {
            ForEach(friends, id: \.self) { friendUid in
                NavigationLink {
                    PublicProfileView(targetUid: friendUid)
                } label: {
                    FriendRow(uid: friendUid)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No friends yet")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Load

    func loadFriends() async {
        isLoading = true

        if uid == friendService.myUid {
            // 👈 내 친구 목록
            friends = friendService.friends
        } else {
            // 👈 상대 친구 목록 (읽기 전용)
            friends = await fetchOtherUserFriends(uid: uid)
        }

        isLoading = false
    }

    // MARK: - Fetch Other User Friends

    func fetchOtherUserFriends(uid: String) async -> [String] {
        let db = Firestore.firestore()

        let snap = try? await db
            .collection("users")
            .document(uid)
            .collection("friends")
            .getDocuments()

        return snap?.documents.map { $0.documentID } ?? []
    }
}

struct FriendRow: View {
    let uid: String
    @StateObject private var profileVM: ProfileViewModel

    init(uid: String) {
        self.uid = uid
        _profileVM = StateObject(
            wrappedValue: ProfileViewModel(uid: uid)
        )
    }

    var body: some View {
        NavigationLink {
            PublicProfileView(targetUid: uid)
        } label: {
            HStack(spacing: 12) {
                if let url = URL(string: profileVM.profileImageURL),
                   !profileVM.profileImageURL.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                }

                Text(profileVM.username)
                    .font(.headline)

                Spacer()
            }
        }
    }
}
