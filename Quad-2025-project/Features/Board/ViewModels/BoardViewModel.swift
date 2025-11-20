//
//  BoardViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

@MainActor
class BoardViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var lastDoc: DocumentSnapshot?
    @Published var selectedSort: SortType = .latest
    @Published var selectedCategory: String = "All"

    let db = Firestore.firestore()
    var uid: String { Auth.auth().currentUser?.uid ?? "" }

    enum SortType: String, CaseIterable {
        case latest = "Latest"
        case top = "Top"
    }

    let categories = ["All", "Notice", "Question", "Free", "Info"]

    func reset() {
        posts = []
        lastDoc = nil
    }

    func fetchMore() async {
        guard !isLoading else { return }
        isLoading = true

        var query = db.collection("posts").limit(to: 10)

        switch selectedSort {
        case .latest:
            query = query.order(by: "timestamp", descending: true)
        case .top:
            query = query.order(by: "likeCount", descending: true)
        }

        if selectedCategory != "All" {
            query = query.whereField("category", isEqualTo: selectedCategory)
        }

        if let last = lastDoc {
            query = query.start(afterDocument: last)
        }

        do {
            let snap = try await query.getDocuments()
            lastDoc = snap.documents.last

            let newPosts = snap.documents.compactMap { try? $0.data(as: Post.self) }

            // 🔥 중복 방지 필터
            let filtered = newPosts.filter { newPost in
                !posts.contains(where: { $0.id == newPost.id })
            }

            posts.append(contentsOf: filtered)

        } catch {
            print("❌ Fetch error:", error)
        }

        isLoading = false
    }


    // MARK: - Create Post (Multiple Images)
    func createPost(title: String,
                    content: String,
                    category: String,
                    images: [UIImage]) async {

        var imageURLs: [String] = []

        // 🔥 이미지 1개씩 업로드
        for img in images {
            if let url = await uploadImage(img) {
                imageURLs.append(url)
            }
        }

        let newPost = Post(
            authorId: uid,
            title: title,
            content: content,
            timestamp: Date(),   // ← 반드시 여기에!
            images: imageURLs,
            category: category,
            likeCount: 0,
            commentCount: 0
        )


        do {
            _ = try db.collection("posts").addDocument(from: newPost)
            reset()
            await fetchMore()
        } catch {
            print("❌ Create error:", error)
        }
    }

    private func uploadImage(_ image: UIImage) async -> String? {
        let ref = Storage.storage().reference()
            .child("post_images/\(UUID().uuidString).jpg")

        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }

        do {
            _ = try await ref.putDataAsync(data)
            return try await ref.downloadURL().absoluteString
        } catch {
            return nil
        }
    }

    // MARK: - Delete
    func deletePost(_ post: Post) async {
        guard let id = post.id else { return }
        try? await db.collection("posts").document(id).delete()
        posts.removeAll { $0.id == id }
    }
}
