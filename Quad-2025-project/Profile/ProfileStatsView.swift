//
//  ProfileStatsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

//
//  ProfileStatsView.swift
//

import SwiftUI

struct ProfileStatsView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        HStack(spacing: 28) {

            statBlock(number: viewModel.postsCount, title: "Posts")
            statBlock(number: viewModel.followersCount, title: "Followers")
            statBlock(number: viewModel.followingCount, title: "Following")

        }
    }

    private func statBlock(number: Int, title: String) -> some View {
        VStack(spacing: 4) {
            Text("\(number)")
                .font(.headline)
            Text(title)
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}
