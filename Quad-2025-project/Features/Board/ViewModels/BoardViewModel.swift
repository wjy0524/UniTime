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
    
    // 🔥 NEW: Firestore listener for real-time updates
    private var listener: ListenerRegistration?

    enum SortType: String, CaseIterable {
        case latest = "Latest"
        case top = "Top"
    }

    let categories = ["All", "Notice", "Question", "Free", "Info"]

    init() {
        // 🔥 Listen for post updates (likes/comments changed) - Keep for local updates
        NotificationCenter.default.addObserver(
            forName: .didUpdatePost,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let postId = notification.userInfo?["postId"] as? String else { return }
            
            Task {
                await self.refreshPost(postId: postId)
            }
        }
    }
    
    // 🔥 NEW: Clean up listener when ViewModel is deallocated
    deinit {
        listener?.remove()
    }

    func reset() {
        posts = []
        lastDoc = nil
        listener?.remove()  // 🔥 Remove old listener
        listener = nil
    }
    
    // 🔥 NEW: Start real-time listening for posts
    func startListening() {
        // Remove existing listener first
        listener?.remove()
        
        var query: Query = db.collection("posts").limit(to: 20)
        
        // Apply sort
        switch selectedSort {
        case .latest:
            query = query.order(by: "timestamp", descending: true)
        case .top:
            query = query.order(by: "likeCount", descending: true)
        }
        
        // Apply category filter
        if selectedCategory != "All" {
            query = query.whereField("category", isEqualTo: selectedCategory)
        }
        
        // 🔥 Add snapshot listener for real-time updates
        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Listener error:", error)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Update posts on main thread
            Task { @MainActor in
                self.posts = documents.compactMap { try? $0.data(as: Post.self) }
                self.lastDoc = documents.last
                self.isLoading = false
            }
        }
        
        isLoading = true
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

        // 🔥 FIX: Category filtering with exact match
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

    // 🔥 NEW: Refresh a single post's data
    func refreshPost(postId: String) async {
        do {
            let doc = try await db.collection("posts").document(postId).getDocument()
            guard let updatedPost = try? doc.data(as: Post.self) else { return }
            
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index] = updatedPost
            }
        } catch {
            print("❌ Refresh post error:", error)
        }
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
            timestamp: Date(),
            images: imageURLs,
            category: category,  // 🔥 Make sure this matches exactly: "Free", "Notice", etc.
            likeCount: 0,
            commentCount: 0,
            keywords: generateKeywords(title: title, content: content)
        )

        do {
            _ = try db.collection("posts").addDocument(from: newPost)
            // 🔥 No need to manually refresh - listener will pick up the new post automatically
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
        // 🔥 No need to manually remove - listener will update automatically
    }
    
    func fixAllCommentCounts() async {
        print("🔧 Fixing comment counts...")
        
        do {
            let postsSnap = try await db.collection("posts").getDocuments()
            
            for postDoc in postsSnap.documents {
                let postId = postDoc.documentID
                
                let commentsSnap = try await db.collection("posts")
                    .document(postId)
                    .collection("comments")
                    .getDocuments()
                
                let actualCount = commentsSnap.documents.count
                
                try await db.collection("posts")
                    .document(postId)
                    .updateData(["commentCount": actualCount])
                
                print("✅ Fixed post \(postId): \(actualCount) comments")
            }
            
            print("🎉 Done!")
            // 🔥 Listener will automatically refresh the data
            
        } catch {
            print("❌ Error:", error)
        }
    }
}

// 🔥 NEW: Notification for post updates
extension Notification.Name {
    static let didUpdatePost = Notification.Name("didUpdatePost")
}

extension BoardViewModel {

    func generateKeywords(title: String, content: String) -> [String] {
        let text = "\(title) \(content)"
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z0-9가-힣 ]",
                with: "",
                options: .regularExpression
            )

        let words = text.split(separator: " ")
        return Array(Set(words.map { String($0) }))
    }
}
