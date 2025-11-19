//
//  ProfileEditView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//
import SwiftUI
import PhotosUI

struct ProfileEditView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // MARK: - Profile Image Section
                    profileImageSection

                    // MARK: - Editable Fields Section
                    VStack(spacing: 20) {
                        EditableInputCard(title: "Username", text: $viewModel.username)
                        EditableInputCard(title: "Major", text: $viewModel.major)
                        EditableInputCard(title: "Year", text: $viewModel.year)
                        EditableInputCard(title: "Email", text: $viewModel.email)
                        EditableInputCard(title: "Phone", text: $viewModel.phone)
                        EditableBioCard(text: $viewModel.bio)
                    }
                    .padding(.horizontal)
                    
                }
                .padding(.top, 20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.updateProfile(profileImage: profileImage)
                            dismiss()
                        }
                    }
                    .bold()
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


// MARK: - Profile Image Section
extension ProfileEditView {
    var profileImageSection: some View {
        VStack(spacing: 14) {
            if let profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            } else if let url = URL(string: viewModel.profileImageURL), !viewModel.profileImageURL.isEmpty {
                AsyncImage(url: url) { img in
                    img.resizable()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 110, height: 110)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("Edit Profile Photo")
                    .foregroundColor(Color("UTAustinOrange"))
                    .font(.subheadline.bold())
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                    }
                }
            }
        }
    }
}


// MARK: - Edit Field Card (Reusable)
struct EditableInputCard: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("", text: $text)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
                )
        }
    }
}


// MARK: - Bio Card
struct EditableBioCard: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bio")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextEditor(text: $text)
                .frame(height: 120)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
                )
        }
    }
}
