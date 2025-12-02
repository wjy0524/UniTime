//
//  SearchUserView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import Kingfisher
import SwiftUI

struct SearchUserView: View {

    @StateObject var vm = SearchUserViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search username…", text: $vm.query)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: vm.query) {
                        Task { await vm.search() }
                    }

                List(vm.results) { user in
                    NavigationLink {
                        PublicProfileView(targetUid: user.uid)
                    } label: {
                        HStack {
                            if let url = URL(string: user.profileImageURL),
                                !user.profileImageURL.isEmpty
                            {
                                KFImage(url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    )
                            }

                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .font(.headline)
                                Text("\(user.major) · \(user.year)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search Users")
        }
    }
}
