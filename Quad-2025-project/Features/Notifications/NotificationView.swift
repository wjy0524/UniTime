//
//  NotificationView.swift
//  Quad-2025-project
//
//  Created on Notification Feature Implementation
//

//
//  NotificationView.swift
//  Quad-2025-project
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Navigation Target
enum NotificationNavTarget: Hashable {
    case user(uid: String)
    case post(postId: String)
    case eventRequests 
}

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var navTarget: NotificationNavTarget?

    var body: some View {
        NavigationStack {
            ZStack {

                // 메인 콘텐츠
                if viewModel.isLoading {
                    ProgressView("Loading notifications...")
                } else if viewModel.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)

            // 🔥 PUSH 네비게이션 (핵심)
            .navigationDestination(item: $navTarget) { target in
                switch target {
                case .user(let uid):
                    PublicProfileView(targetUid: uid)

                case .post(let postId):
                    PostDetailLoaderView(postId: postId)
                    
                case .eventRequests:
                    EventShareRequestsView()

                }
            }

            .onAppear {
                viewModel.startListening()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.markAllAsRead()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.notifications.isEmpty {
                        Button("Mark all read") {
                            viewModel.markAllAsRead()
                        }
                        .font(.subheadline)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    // MARK: - Empty State
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Notifications")
                .font(.title2.bold())

            Text("You're all caught up!")
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Notification List
    var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(
                        notification: notification,
                        onTap: {
                            handleNotificationTap(notification)
                        },
                        onDelete: {
                            viewModel.deleteNotification(notification)
                        }
                    )
                    .onAppear {
                        if !notification.isRead {
                            viewModel.markAsRead(notification)
                        }
                    }

                    Divider().padding(.leading, 70)
                }
            }
        }
    }

    // MARK: - Tap Handling (🔥 핵심 로직)
    func handleNotificationTap(_ notification: AppNotification) {

        if !notification.isRead {
            viewModel.markAsRead(notification)
        }

        switch notification.type {

        // 👤 친구 요청 / 수락 → 프로필로
        case .follow, .followAccepted:
            navTarget = .user(uid: notification.fromUserId)

        // 📝 게시글 관련 → 게시글로
        case .postLike, .postComment:
            if let postId = notification.postId {
                navTarget = .post(postId: postId)
            }
            // 📅 이벤트 공유 요청
        case .eventInvite:   // ← 네가 알림 만들 때 쓴 type
            if let eventId = notification.eventId {
                navTarget = .eventRequests
                }
        

        // (지금은 이동 없음)
            //추후 업데이트 해야함
        case .timetableShareRequest,
             .timetableShareAccepted,
             .timetableShareDeclined,
             .chatMessage:
            break
        }
    }
}

// MARK: - Notification Row (그대로 유지)
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var isProcessing = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(notificationColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: notification.type.icon)
                    .foregroundColor(notificationColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.subheadline)

                Text(notification.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    var notificationColor: Color {
        switch notification.type.color {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
    }
}

struct PostDetailLoaderView: View {
    let postId: String
    @State private var post: Post?

    var body: some View {
        Group {
            if let post {
                PostDetailView(post: post)
            } else {
                ProgressView()
                    .task {
                        let snap = try? await Firestore.firestore()
                            .collection("posts")
                            .document(postId)
                            .getDocument()
                        post = try? snap?.data(as: Post.self)
                    }
            }
        }
    }
}

