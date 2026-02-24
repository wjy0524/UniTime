//
//  CourseChatListView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//
import SwiftUI

// ✅ CourseChatView에서 쓰던 DiscordTheme를 그대로 사용한다고 가정
// (DiscordTheme.bg(_ scheme: ColorScheme) 형태)

struct CourseChatListView: View {
    @StateObject var vm = CourseChatListViewModel()
    @Environment(\.colorScheme) private var scheme

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
            .background(DiscordTheme.bg(scheme).ignoresSafeArea())
            .navigationTitle("Course Chats")
            .toolbarBackground(DiscordTheme.bg(scheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            vm.startListening()
        }
    }

    // MARK: - Chat Card

    func chatCard(_ chat: CourseChat) -> some View {
        HStack(spacing: 14) {

            Circle()
                .fill(Color("UTAustinOrange").opacity(scheme == .dark ? 0.18 : 0.12))
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
                        .foregroundColor(DiscordTheme.primaryText(scheme))

                    Spacer()

                    if let time = chat.lastMessageTime {
                        Text(time, style: .time)
                            .font(.caption2)
                            .foregroundColor(DiscordTheme.secondaryText(scheme))
                    }
                }

                HStack {

                    if let last = chat.lastMessage {

                        if chat.lastSenderId == vm.uid {
                            Text("You: \(last)")
                                .font(.subheadline)
                                .foregroundColor(DiscordTheme.secondaryText(scheme))
                                .lineLimit(1)
                        } else if let sender = chat.lastSenderName {
                            Text("\(sender): \(last)")
                                .font(.subheadline)
                                .foregroundColor(DiscordTheme.secondaryText(scheme))
                                .lineLimit(1)
                        } else {
                            Text(last)
                                .font(.subheadline)
                                .foregroundColor(DiscordTheme.secondaryText(scheme))
                                .lineLimit(1)
                        }

                    } else {
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundColor(DiscordTheme.secondaryText(scheme))
                    }

                    Spacer()

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
                    .foregroundColor(DiscordTheme.secondaryText(scheme))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(DiscordTheme.divider(scheme), lineWidth: scheme == .dark ? 0 : 1)
                )
        )
    }

    private var cardBg: Color {
        scheme == .dark
        ? Color.white.opacity(0.06)
        : Color.white
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 42))
                .foregroundColor(DiscordTheme.secondaryText(scheme))

            Text("No Course Chats Yet")
                .font(.headline)
                .foregroundColor(DiscordTheme.primaryText(scheme))

            Text("Add a course in your timetable to automatically join a chat room.")
                .font(.subheadline)
                .foregroundColor(DiscordTheme.secondaryText(scheme))
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
