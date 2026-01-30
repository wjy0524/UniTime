//
//  MyProfileView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/30/26.
//



import SwiftUI
import FirebaseAuth

struct MyProfileView: View {

    @StateObject private var viewModel: ProfileViewModel
    @State private var selectedTab = 0   // ✅ 여기로 이동

    init() {
        let uid = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(
            wrappedValue: ProfileViewModel(uid: uid)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ProfileHeaderView(viewModel: viewModel)

                    ProfileMetaView(
                        major: viewModel.major,
                        grade: viewModel.year,
                        email: viewModel.email,
                        phone: viewModel.phone
                    )

                    tabPicker
                    tabContent
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}


////////////////////////////////////////////////////////////
// MARK: - Tabs
////////////////////////////////////////////////////////////

extension MyProfileView {

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
            ProfileAboutView(bio: viewModel.bio)
        default:
            EmptyView()
        }
    }
}
