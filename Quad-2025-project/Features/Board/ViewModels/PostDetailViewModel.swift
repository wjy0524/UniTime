//
//  PostDetailViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var commentText = ""
    @Published var likeCount = 0
    @Published var didLike = false
    @Published var replyingTo: Comment? = nil
    @Published var authorName = ""

    let db = Firestore.firestore()
    var uid: String { Auth.auth().currentUser?.uid ?? "" }
    
    // 🔥 NEW: Firestore listeners for real-time updates
    private var postListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?
    
    // 🔥 NEW: Clean up listeners
    deinit {
        postListener?.remove()
        commentsListener?.remove()
    }
    
    // 🔥 NEW: Call this to stop listeners when view disappears
    func stopListening() {
        postListener?.remove()
        commentsListener?.remove()
        postListener = nil
        commentsListener = nil
    }

    func load(post: Post) async {
        likeCount = post.likeCount

        // 🔥 authorId → username 변환
        if let username = await fetchUsername(uid: post.authorId) {
            self.authorName = username
        } else {
            self.authorName = post.authorId
        }

        await checkLiked(post)
        
        // 🔥 Start real-time listeners
        startPostListener(post: post)
        startCommentsListener(post: post)
    }
    
    // 🔥 NEW: Real-time listener for post (likes count)
    func startPostListener(post: Post) {
        guard let postId = post.id else { return }
        
        postListener?.remove()
        
        postListener = db.collection("posts").document(postId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Post listener error:", error)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let newLikeCount = data["likeCount"] as? Int else { return }
                
                Task { @MainActor in
                    self.likeCount = newLikeCount
                }
            }
    }
    
    // 🔥 NEW: Real-time listener for comments
    func startCommentsListener(post: Post) {
        guard let postId = post.id else { return }
        
        commentsListener?.remove()
        
        commentsListener = db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Comments listener error:", error)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    var loaded = documents.compactMap { try? $0.data(as: Comment.self) }
                    
                    // 🔥 UID -> username 변환
                    for i in 0..<loaded.count {
                        let uid = loaded[i].authorId
                        if let username = await self.fetchUsername(uid: uid) {
                            loaded[i].authorId = username
                        }
                    }
                    
                    self.comments = loaded
                }
            }
    }

    // MARK: - Likes
    func checkLiked(_ post: Post) async {
        guard let id = post.id else { return }

        let doc = try? await db.collection("users")
            .document(uid)
            .collection("likes")
            .document(id)
            .getDocument()

        didLike = doc?.exists ?? false
    }

    func toggleLike(_ post: Post) async {
        print("🔔 TOGGLE LIKE: Function called for post \(post.id ?? "unknown")")
        guard let id = post.id else {
            print("❌ TOGGLE LIKE: Post has no ID")
            return
        }

        print("🔔 TOGGLE LIKE: didLike = \(didLike), post author = \(post.authorId)")

        if didLike {
            try? await db.collection("posts").document(id)
                .updateData(["likeCount": FieldValue.increment(Int64(-1))])

            try? await db.collection("users").document(uid)
                .collection("likes").document(id).delete()

            // 🔥 REMOVED: likeCount -= 1 (listener will handle this now)
        } else {
            try? await db.collection("posts").document(id)
                .updateData(["likeCount": FieldValue.increment(Int64(1))])

            try? await db.collection("users").document(uid)
                .collection("likes").document(id).setData([:])

            // 🔥 REMOVED: likeCount += 1 (listener will handle this now)

            // 🔥 Send notification using main notification system
            print("🔔 TOGGLE LIKE: Preparing to send notification to \(post.authorId)")
            let notificationVM = NotificationViewModel()
            notificationVM.sendPostLikeNotification(
                toUserId: post.authorId,
                postId: id
            )
            print("✅ TOGGLE LIKE: Notification function called")
        }

        didLike.toggle()
        
        // 🔥 FIX: Notify BoardView to refresh this post
        NotificationCenter.default.post(
            name: .didUpdatePost,
            object: nil,
            userInfo: ["postId": id]
        )
    }

    // MARK: - Comments + Replies
    // 🔥 REMOVED: loadComments() - now handled by real-time listener

    func addComment(_ post: Post) async {
        guard !commentText.isEmpty else { return }
        guard let postId = post.id else { return }

        let comment = Comment(
            authorId: uid,
            text: commentText,
            likeCount: 0,
            timestamp: Date(),
            replyTo: replyingTo?.id
        )

        try? _ = db.collection("posts")
            .document(postId)
            .collection("comments")
            .addDocument(from: comment)

        try? await db.collection("posts").document(postId)
            .updateData(["commentCount": FieldValue.increment(Int64(1))])

        // 🔥 알림 (댓글 or 대댓글)
        let notificationVM = NotificationViewModel()
        if let parent = replyingTo {
            notificationVM.sendPostCommentNotification(
                toUserId: parent.authorId,
                postId: postId
            )
        } else {
            notificationVM.sendPostCommentNotification(
                toUserId: post.authorId,
                postId: postId
            )
        }

        commentText = ""
        replyingTo = nil
        // 🔥 REMOVED: await loadComments(post) - listener will handle this
        
        // 🔥 FIX: Notify BoardView to refresh this post's comment count
        NotificationCenter.default.post(
            name: .didUpdatePost,
            object: nil,
            userInfo: ["postId": postId]
        )
    }

    func likeComment(post: Post, comment: Comment) async {
        guard let postId = post.id,
            let commentId = comment.id
        else { return }

        try? await db.collection("posts")
            .document(postId)
            .collection("comments")
            .document(commentId)
            .updateData(["likeCount": FieldValue.increment(Int64(1))])

        // 🔥 Send notification using main notification system
        let notificationVM = NotificationViewModel()
        notificationVM.sendPostCommentNotification(
            toUserId: comment.authorId,
            postId: postId
        )

        // 🔥 REMOVED: await loadComments(post) - listener will handle this
    }

    // MARK: - Helper Functions
    func fetchUsername(uid: String) async -> String? {
        do {
            let snap = try await db.collection("users")
                .document(uid)
                .getDocument()

            if let user = try? snap.data(as: QuadUser.self) {
                return user.username
            }

        } catch {
            print("❌ Username fetch error:", error)
        }
        return nil
    }
}
