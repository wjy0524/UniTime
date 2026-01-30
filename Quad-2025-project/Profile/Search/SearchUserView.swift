//
//  SearchUserView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import SwiftUI
import Kingfisher

struct SearchUserView: View {

    @StateObject private var vm = SearchUserViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 🔍 Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search users", text: $vm.query)
                        .focused($isSearchFocused)
                        .textInputAutocapitalization(.never)
                        .onChange(of: vm.query) {
                            Task { await vm.search() }
                        }

                    if !vm.query.isEmpty {
                        Button {
                            vm.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding()

                // 📦 Content States
                if vm.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()

                } else if vm.query.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Search by username")
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                } else if vm.results.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No users found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.results) { user in
                                NavigationLink {
                                    PublicProfileView(targetUid: user.uid)
                                } label: {
                                    UserSearchRow(user: user)
                                }

                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct UserSearchRow: View {
    let user: QuadUser

    var body: some View {
        HStack(spacing: 12) {

            if let imageURL = user.profileImageURL,
               !imageURL.isEmpty,
               let url = URL(string: imageURL) {

                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

            } else {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }


            VStack(alignment: .leading, spacing: 2) {
                Text(user.username ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                let subtitle: String = {
                    switch (user.major, user.year) {
                    case let (m?, y?): return "\(m) · \(y)"
                    case let (m?, nil): return m
                    case let (nil, y?): return y
                    default: return ""
                    }
                }()

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }


            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
