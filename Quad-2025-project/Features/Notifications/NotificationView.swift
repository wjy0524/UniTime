//
//  NotificationView.swift
//  Quad-2025-project
//
//  Created on Notification Feature Implementation
//

import FirebaseAuth
import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUserId: String?

    var body: some View {
        NavigationStack {
            ZStack {

                // 🔹 메인 콘텐츠
                if viewModel.isLoading {
                    ProgressView("Loading notifications...")
                } else if viewModel.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationList
                }

                // 🔥 숨김 NavigationLink (같은 ZStack 안!)
                NavigationLink(
                    destination:
                        selectedUserId.map { uid in
                            PublicProfileView(targetUid: uid)
                        },
                    isActive: Binding(
                        get: { selectedUserId != nil },
                        set: { if !$0 { selectedUserId = nil } }
                    )
                ) {
                    EmptyView()
                }

            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.startListening()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.markAllAsRead()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.notifications.isEmpty {
                        Button {
                            viewModel.markAllAsRead()
                        } label: {
                            Text("Mark all read")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
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
                .font(.title2)
                .bold()

            Text("You're all caught up!")
                .font(.subheadline)
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

                    Divider()
                        .padding(.leading, 70)
                }
            }
        }
    }

    // MARK: - Handle Notification Actions

    func handleNotificationTap(_ notification: AppNotification) {

        if !notification.isRead {
            viewModel.markAsRead(notification)
        }

        switch notification.type {
        case .follow, .followAccepted:
                selectedUserId = notification.fromUserId   // 🔥 여기

        case .timetableShareRequest:
            break

        case .timetableShareAccepted, .timetableShareDeclined:
            break

        case .postLike, .postComment:
            break

        case .eventInvite:
            break

        case .chatMessage:
            break
        }
    }
}

// MARK: - Notification Row

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
                    .font(.system(size: 20))
                    .foregroundColor(notificationColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Text(notification.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if notification.type == .timetableShareRequest && !isProcessing {
                    timetableShareActions
                }
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
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

    var timetableShareActions: some View {
        HStack(spacing: 12) {
            Button {
                isProcessing = true
                if let shareId = notification.timetableShareId {
                    TimetableShareViewModel.shared.declineShareRequest(shareId)
                }
            } label: {
                Text("Decline")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Button {
                isProcessing = true
                if let shareId = notification.timetableShareId {
                    TimetableShareViewModel.shared.acceptShareRequest(shareId)
                }
            } label: {
                Text("Accept")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }
}

// MARK: - Preview

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
