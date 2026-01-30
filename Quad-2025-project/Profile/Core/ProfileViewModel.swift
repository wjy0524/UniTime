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
    @Published var friendsCount: Int = 0   // ✅ friends 기준

    private let db = Firestore.firestore()
    private var friendsListener: ListenerRegistration?

    // ⭐️ 현재 보고 있는 프로필 UID
    let targetUid: String

    // MARK: - 내 UID
    var myUid: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    // MARK: - Init (다른 유저 / 내 프로필 공용)
    init(uid: String) {
        self.targetUid = uid

        // 🔔 Like 변경 감지
        NotificationCenter.default.addObserver(
            forName: .didUpdateLikes,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.fetchLikedPosts(for: self.targetUid)
            }
        }

        Task {
            await loadProfile(for: uid)
            startFriendsListener(for: uid)
            await fetchUserPosts(for: uid)
            await fetchLikedPosts(for: uid)
        }
    }

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
            self.username = data.username ?? "Unknown"
            self.major = data.major ?? ""
            self.year = data.year ?? ""
            self.email = data.email ?? ""
            self.phone = data.phone ?? ""
            self.bio = data.bio ?? ""
            self.profileImageURL = data.profileImageURL ?? ""


        } catch {
            print("❌ Failed loading profile:", error)
        }
    }

    // MARK: - Friends Count (🔥 핵심 변경)
    func fetchFriendsCount(for uid: String) async {
        do {
            let snap = try await db
                .collection("users")
                .document(uid)
                .collection("friends")
                .getDocuments()

            self.friendsCount = snap.documents.count
        } catch {
            print("❌ fetchFriendsCount error:", error)
        }
    }
    
    func startFriendsListener(for uid: String) {
        friendsListener?.remove()   // 중복 방지

        friendsListener = db
            .collection("users")
            .document(uid)
            .collection("friends")
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                if let error {
                    print("❌ friends listener error:", error)
                    return
                }
                self.friendsCount = snap?.documents.count ?? 0
            }
    }


    // MARK: - Update Profile
    func updateProfile(profileImage: UIImage?) async {

        guard myUid == targetUid else { return }

        var imageURL = profileImageURL

        if let img = profileImage {
            if let url = await uploadProfileImage(img, uid: myUid) {
                imageURL = url
            }
        }

        let updatedUser = QuadUser(
            uid: myUid,
            username: username,
            username_lower: username.lowercased(),
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

            guard !ids.isEmpty else {
                self.likedPosts = []
                return
            }

            let postsSnap = try await db.collection("posts")
                .whereField(FieldPath.documentID(), in: ids)
                .getDocuments()

            self.likedPosts = postsSnap.documents.compactMap {
                try? $0.data(as: Post.self)
            }

        } catch {
            print("❌ Failed loading liked posts:", error)
        }
    }
    
    deinit {
            friendsListener?.remove()
            print("🧹 ProfileViewModel deinit - friends listener removed")
    }

}
