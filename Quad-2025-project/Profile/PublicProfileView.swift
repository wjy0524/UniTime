//
//  PublicProfileView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.

//
//  PublicProfileView.swift
//  Quad-2025-project
//

import FirebaseAuth
import Kingfisher
import SwiftUI

struct PublicProfileView: View {
    let targetUid: String
    @StateObject private var viewModel: ProfileViewModel
    @State private var selectedTab = 0

    init(targetUid: String) {
        self.targetUid = targetUid
        _viewModel = StateObject(wrappedValue: ProfileViewModel(uid: targetUid))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    userInfoSection
                    statsSection
                    tabPicker
                    tabContent
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.username)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // ⭐️ Back 버튼 텍스트 제거 (핵심)
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }

                // ⚙️ Settings
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
        }
    }
}



////////////////////////////////////////////////////////////
// MARK: - HEADER
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
                    .overlay(Circle().stroke(.white, lineWidth: 3))
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
// MARK: - USER INFO
////////////////////////////////////////////////////////////

extension PublicProfileView {
    var userInfoSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.username)
                .font(.title3.bold())

            if !viewModel.major.isEmpty {
                Text("\(viewModel.year) · \(viewModel.major)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - STATS (Followers / Following 클릭 가능)
////////////////////////////////////////////////////////////

extension PublicProfileView {
    var statsSection: some View {
        HStack(spacing: 36) {

            statItem(viewModel.postsCount, "Posts")

            NavigationLink {
                FollowListView(uid: targetUid, type: .followers)
            } label: {
                statItem(viewModel.followersCount, "Followers")
            }

            NavigationLink {
                FollowListView(uid: targetUid, type: .following)
            } label: {
                statItem(viewModel.followingCount, "Following")
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    func statItem(_ value: Int, _ title: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - TAB PICKER + CONTENT
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
            Text(viewModel.bio.isEmpty ? "No bio added yet." : viewModel.bio)
                .foregroundColor(.secondary)
                .padding(.top, 12)

        default:
            EmptyView()
        }
    }
}
