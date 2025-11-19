//
//  ProfileViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//
//
//  ProfileViewModel.swift
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: - Published States
    @Published var user: QuadUser? = nil

    @Published var username: String = ""
    @Published var major: String = ""
    @Published var year: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var bio: String = ""
    @Published var profileImageURL: String = ""

    // ⭐ 바로 여기!
    @Published var userPosts: [Post] = []
    @Published var likedPosts: [Post] = []

    // ⭐ 여기에 넣어야 함
    @Published var postsCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0

    private let db = Firestore.firestore()

    private var uid: String? {
        Auth.auth().currentUser?.uid
    }

    var userId: String {
        uid ?? ""
    }

    // MARK: - Init
    init() {
        Task {
            await loadProfile()
            await fetchUserPosts()
            await fetchLikedPosts()
        }
    }

    // MARK: - Load Profile
    func loadProfile() async {
        guard let uid else { return }

        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            let data = try snapshot.data(as: QuadUser.self)


            self.user = data
            self.username = data.username
            self.major = data.major
            self.year = data.year
            self.email = data.email
            self.phone = data.phone
            self.bio = data.bio
            self.profileImageURL = data.profileImageURL

        } catch {
            print("❌ Failed loading profile:", error)
        }
    }

    // MARK: - Update Profile
    func updateProfile(profileImage: UIImage?) async {

        guard let uid else { return }

        var imageURL = profileImageURL

        if let img = profileImage {
            if let url = await uploadProfileImage(img, uid: uid) {
                imageURL = url
            }
        }

        let updatedUser = QuadUser(
            uid: uid,
            username: username,
            major: major,
            year: year,
            email: email,
            phone: phone,
            bio: bio,
            profileImageURL: imageURL
        )

        do {
            try db.collection("users").document(uid).setData(from: updatedUser)
            self.user = updatedUser
        } catch {
            print("❌ Failed saving profile:", error)
        }
    }

    private func uploadProfileImage(_ image: UIImage, uid: String) async -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }

        let ref = Storage.storage().reference()
            .child("profile_images/\(uid).jpg")

        do {
            _ = try await ref.putDataAsync(data)
            return try await ref.downloadURL().absoluteString
        } catch {
            print("❌ Upload Error:", error)
            return nil
        }
    }

    // MARK: - Fetch User Posts
    func fetchUserPosts() async {
        do {
            let snap = try await db.collection("posts")
                .whereField("authorId", isEqualTo: userId)
                .getDocuments()

            self.userPosts = snap.documents.compactMap {
                try? $0.data(as: Post.self)
            }

            // ⭐ 여기서 카운트 업데이트!
            self.postsCount = self.userPosts.count

        } catch {
            print("❌ Failed loading user posts:", error)
        }
    }

    // MARK: - Fetch Liked Posts
    func fetchLikedPosts() async {

        do {
            let snap = try await db.collection("likes")
                .document(userId)
                .collection("userLikes")
                .getDocuments()

            let ids = snap.documents.map { $0.documentID }

            if ids.isEmpty {
                self.likedPosts = []
                return
            }

            let snap2 = try await db.collection("posts")
                .whereField("id", in: ids)
                .getDocuments()

            self.likedPosts = snap2.documents.compactMap {
                try? $0.data(as: Post.self)
            }

        } catch {
            print("❌ Failed loading liked posts:", error)
        }
    }
}
