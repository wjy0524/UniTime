//
//  CourseChatListView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import SwiftUI

struct CourseChatListView: View {
    @StateObject var vm = CourseChatListViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {

                    if vm.chats.isEmpty {
                        emptyState
                    }

                    ForEach(vm.chats) { chat in
                        NavigationLink {
                            CourseChatView(chat: chat)
                        } label: {
                            chatCard(chat)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Course Chats")
        }
        .onAppear {
            vm.startListening()
        }
    }

    // MARK: - Chat Card

    func chatCard(_ chat: CourseChat) -> some View {
        HStack(spacing: 14) {

            // Avatar
            Circle()
                .fill(Color("UTAustinOrange").opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(initials(from: chat.courseCode))
                        .font(.headline)
                        .foregroundColor(Color("UTAustinOrange"))
                )

            VStack(alignment: .leading, spacing: 6) {

                HStack {
                    Text(chat.courseCode)
                        .font(.headline)

                    Spacer()

                    if let time = chat.lastMessageTime {
                        Text(time, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {

                    if let last = chat.lastMessage {

                        if chat.lastSenderId == vm.uid {
                            // 🔥 내가 보낸 메시지
                            Text("You: \(last)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        else if let sender = chat.lastSenderName {
                            // 🔥 다른 사람이 보낸 메시지
                            Text("\(sender): \(last)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        else {
                            Text(last)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                    } else {
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 🔴 UNREAD BADGE
                    if let id = chat.id,
                       let unread = vm.unreadCounts[id],
                       unread > 0 {

                        Text(unread > 99 ? "99+" : "\(unread)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }

                Text("\(chat.members.count) members")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 42))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Course Chats Yet")
                .font(.headline)

            Text("Add a course in your timetable to automatically join a chat room.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 80)
    }

    // MARK: - Helpers

    func initials(from code: String) -> String {
        let parts = code.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(code.prefix(2))
    }
}
