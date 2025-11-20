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

    @Published var userPosts: [Post] = []
    @Published var likedPosts: [Post] = []

    @Published var postsCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0

    private let db = Firestore.firestore()

    // ⭐️ 현재 보고 있는 프로필의 UID
    let targetUid: String

    // MARK: - 내 계정 UID
    var myUid: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    // MARK: - Init for other user profile
    init(uid: String) {
        self.targetUid = uid
        Task {
            await loadProfile(for: uid)
            await fetchStats(for: uid)
            await fetchUserPosts(for: uid)
            await fetchLikedPosts(for: uid)
        }
    }

    // MARK: - Init for MY profile
    convenience init() {
        let uid = Auth.auth().currentUser?.uid ?? ""
        self.init(uid: uid)
    }

    // MARK: - Load Profile
    func loadProfile(for uid: String) async {
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

    // MARK: - Load Stats (followers, following)
    func fetchStats(for uid: String) async {
        await fetchFollowersCount(for: uid)
        await fetchFollowingCount(for: uid)
    }

    func fetchFollowersCount(for uid: String) async {
        do {
            let snap = try await db.collection("users")
                .document(uid)
                .collection("followers")
                .getDocuments()

            self.followersCount = snap.documents.count

        } catch {
            print("❌ fetchFollowersCount error:", error)
        }
    }

    func fetchFollowingCount(for uid: String) async {
        do {
            let snap = try await db.collection("users")
                .document(uid)
                .collection("following")
                .getDocuments()

            self.followingCount = snap.documents.count

        } catch {
            print("❌ fetchFollowingCount error:", error)
        }
    }

    // MARK: - Refresh externally
    func refreshStats() async {
        await fetchStats(for: targetUid)
    }

    // MARK: - Update Profile
    func updateProfile(profileImage: UIImage?) async {

        guard myUid == targetUid else { return }  // 내 프로필만 수정 가능

        var imageURL = profileImageURL

        if let img = profileImage {
            if let url = await uploadProfileImage(img, uid: myUid) {
                imageURL = url
            }
        }

        let updatedUser = QuadUser(
            uid: myUid,
            username: username,
            username_lower: username.lowercased(),   // 🔥 추가
            major: major,
            year: year,
            email: email,
            phone: phone,
            bio: bio,
            profileImageURL: imageURL
        )

        do {
            try db.collection("users").document(myUid).setData(from: updatedUser)
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

    // MARK: - Fetch Posts
    func fetchUserPosts(for uid: String) async {
        do {
            let snap = try await db.collection("posts")
                .whereField("authorId", isEqualTo: uid)
                .getDocuments()

            self.userPosts = snap.documents.compactMap {
                try? $0.data(as: Post.self)
            }

            self.postsCount = self.userPosts.count

        } catch {
            print("❌ Failed loading user posts:", error)
        }
    }

    // MARK: - Fetch Likes
    func fetchLikedPosts(for uid: String) async {
        do {
            let snap = try await db
                .collection("users")
                .document(uid)
                .collection("likes")
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
