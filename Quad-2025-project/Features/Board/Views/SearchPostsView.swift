//
//  SearchPostsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import SwiftUI

struct SearchPostsView: View {
    @StateObject var vm = SearchPostsViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search posts…", text: $vm.query)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: vm.query) { _ in
                        Task { await vm.search() }
                    }

                List(vm.results) { post in
                    NavigationLink {
                        PostDetailView(post: post)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(post.title).font(.headline)
                            Text(post.content)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Search Posts")
        }
    }
}
