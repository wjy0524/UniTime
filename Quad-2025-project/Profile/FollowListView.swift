//
//  FollowListView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/7/26.
//

import SwiftUI
import Kingfisher

struct FollowListView: View {
    let uid: String
    let type: FollowListType

    @StateObject private var viewModel = FollowListViewModel()

    var body: some View {
        List(viewModel.users) { user in
            NavigationLink {
                PublicProfileView(targetUid: user.uid)
            } label: {
                HStack(spacing: 12) {

                    avatar(user.profileImageURL)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.username)
                            .font(.headline)

                        Text("\(user.year) · \(user.major)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.plain)
        .navigationTitle(type == .followers ? "Followers" : "Following")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetch(uid: uid, type: type)
        }
    }

    // MARK: - Avatar
    func avatar(_ urlString: String) -> some View {
        Group {
            if let url = URL(string: urlString), !urlString.isEmpty {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color.gray.opacity(0.4))
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }
}
