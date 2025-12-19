//
//  ShareEventView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import FirebaseAuth
import Kingfisher
import SwiftUI

struct ShareEventView: View {
    let event: Event
    let onShare: (String) -> Void
    @Environment(\.dismiss) var dismiss

    @ObservedObject private var friendsManager = FriendsManager.shared
    @State private var friendsList: [UserMini] = []
    @State private var selectedFriend: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Share with") {
                    if friendsList.isEmpty {
                        Text("You don't have any friends yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(friendsList) { user in
                            HStack(spacing: 12) {

                                // 프로필 이미지
                                if let url = URL(string: user.profileImageURL),
                                    !user.profileImageURL.isEmpty
                                {
                                    KFImage(url)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 38, height: 38)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.white.opacity(0.9))
                                        )
                                }

                                VStack(alignment: .leading) {
                                    Text(user.username)
                                        .font(.headline)
                                    Text("@\(user.uid)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedFriend == user.uid {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFriend = user.uid
                            }
                        }
                    }
                }
            }
            .navigationTitle("Share Event")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        if let target = selectedFriend {
                            onShare(target)
                            dismiss()
                        }
                    }
                    .disabled(selectedFriend == nil)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                friendsList = await friendsManager.getFriendsList()
            }
        }
    }
}
