//
//  PostDetailViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var commentText = ""
    @Published var likeCount = 0
    @Published var didLike = false
    @Published var replyingTo: Comment? = nil   // 🔥 대댓글 대상
    @Published var authorName = ""

    let db = Firestore.firestore()
    var uid: String { Auth.auth().currentUser?.uid ?? "" }

    func load(post: Post) async {
        likeCount = post.likeCount

        // 🔥 authorId → username 변환
        if let username = await fetchUsername(uid: post.authorId) {
            self.authorName = username    // ⭐️ 추가되는 변수
        } else {
            self.authorName = post.authorId
        }

        await checkLiked(post)
        await loadComments(post)
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
        guard let id = post.id else { return }

        if didLike {
            try? await db.collection("posts").document(id)
                .updateData(["likeCount": FieldValue.increment(Int64(-1))])

            try? await db.collection("users").document(uid)
                .collection("likes").document(id).delete()

            likeCount -= 1
        } else {
            try? await db.collection("posts").document(id)
                .updateData(["likeCount": FieldValue.increment(Int64(1))])

            try? await db.collection("users").document(uid)
                .collection("likes").document(id).setData([:])

            likeCount += 1

            // 🔥 알림 보내기
            await sendNotification(
                to: post.authorId,
                type: "like_post",
                postId: id,
                message: "liked your post."
            )
        }

        didLike.toggle()
    }

    // MARK: - Comments + Replies
    func loadComments(_ post: Post) async {
        guard let postId = post.id else { return }

        let snap = try? await db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp")
            .getDocuments()

        var loaded = snap?.documents.compactMap { try? $0.data(as: Comment.self) } ?? []

        // 🔥 UID -> username 변환
        for i in 0..<loaded.count {
            let uid = loaded[i].authorId
            if let username = await fetchUsername(uid: uid) {
                loaded[i].authorId = username
            }
        }

        self.comments = loaded
    }


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
        if let parent = replyingTo {
            await sendNotification(
                to: parent.authorId,
                type: "reply_comment",
                postId: postId,
                commentId: parent.id,
                message: "replied to your comment."
            )
        } else {
            await sendNotification(
                to: post.authorId,
                type: "comment_post",
                postId: postId,
                message: "commented on your post."
            )
        }

        commentText = ""
        replyingTo = nil
        await loadComments(post)
    }

    func likeComment(post: Post, comment: Comment) async {
        guard let postId = post.id,
              let commentId = comment.id else { return }

        try? await db.collection("posts")
            .document(postId)
            .collection("comments")
            .document(commentId)
            .updateData(["likeCount": FieldValue.increment(Int64(1))])

        await sendNotification(
            to: comment.authorId,
            type: "like_comment",
            postId: postId,
            commentId: commentId,
            message: "liked your comment."
        )

        await loadComments(post)
    }

    // MARK: - Notifications
    func sendNotification(to userId: String,
                          type: String,
                          postId: String? = nil,
                          commentId: String? = nil,
                          message: String) async {

        guard userId != uid else { return }

        let noti = NotificationItem(
            type: type,
            senderId: uid,
            postId: postId,
            commentId: commentId,
            message: message,
            timestamp: Date(),
            isRead: false
        )

        try? _ = db.collection("users")
            .document(userId)
            .collection("notifications")
            .addDocument(from: noti)
    }
    
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
