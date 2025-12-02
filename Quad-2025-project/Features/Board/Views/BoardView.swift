//
//  BoardView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct BoardView: View {
    @StateObject var vm = BoardViewModel()
    @State private var showCreate = false
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            VStack {

                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(vm.categories, id: \.self) { cat in
                            Text(cat)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    vm.selectedCategory == cat
                                        ? Color("UTAustinOrange").opacity(0.2)
                                        : Color(.systemGray6)
                                )
                                .cornerRadius(10)
                                .onTapGesture {
                                    vm.selectedCategory = cat
                                    vm.reset()
                                    Task { await vm.fetchMore() }
                                }
                        }
                    }
                    .padding(.horizontal)
                }

                // Sort picker
                Picker("", selection: $vm.selectedSort) {
                    Text("Latest").tag(BoardViewModel.SortType.latest)
                    Text("Top").tag(BoardViewModel.SortType.top)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: vm.selectedSort) {
                    vm.reset()
                    Task { await vm.fetchMore() }
                }

                List {
                    ForEach(vm.posts) { post in
                        NavigationLink {
                            PostDetailView(post: post)
                        } label: {
                            postRow(post)
                        }
                    }

                    if !vm.isLoading {
                        Color.clear.onAppear { Task { await vm.fetchMore() } }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Board")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreatePostView(vm: vm)
            }
            .sheet(isPresented: $showSearch) {
                SearchPostsView()
            }
        }
        .task {
            await vm.fetchMore()
        }
    }

    @ViewBuilder
    func postRow(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(post.title)
                .font(.headline)

            Text(post.content)
                .lineLimit(2)
                .foregroundColor(.secondary)

            if let img = post.images.first {
                AsyncImage(url: URL(string: img)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(.gray.opacity(0.3))
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(10)
            }

            HStack {
                Label("\(post.likeCount)", systemImage: "heart")
                Label("\(post.commentCount)", systemImage: "bubble.right")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}
