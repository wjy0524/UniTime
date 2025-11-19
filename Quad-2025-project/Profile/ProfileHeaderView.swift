//
//  ProfileHeaderView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

//
//  ProfileHeaderView.swift
//  Quad-2025-project
//

import SwiftUI
import Kingfisher

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {

            // Banner
            Rectangle()
                .fill(Color("UTAustinOrange").opacity(colorScheme == .dark ? 0.35 : 0.22))
                .frame(height: 130)

            // Avatar
            VStack {
                if let url = URL(string: viewModel.profileImageURL), !viewModel.profileImageURL.isEmpty {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .offset(y: -55)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                        .offset(y: -55)
                }
            }
            .padding(.bottom, -45)

            // Name & username
            VStack(spacing: 4) {
                // Name → username 사용
                Text(viewModel.username)
                    .font(.title2.bold())

                // Username handle
                Text("@\(viewModel.username)")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            .padding(.top, 8)

            // Stats
            ProfileStatsView(viewModel: viewModel)
                .padding(.top, 12)
        }
    }
}
