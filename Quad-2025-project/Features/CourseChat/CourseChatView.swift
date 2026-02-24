//
//  CourseChatView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import SwiftUI

// MARK: - View

struct CourseChatView: View {

    @StateObject var vm = CourseChatViewModel()
    @EnvironmentObject var chatListVM: CourseChatListViewModel

    @State private var isAtBottom = true
    @Environment(\.colorScheme) private var scheme

    let chat: CourseChat

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {

                    ForEach(vm.messages.indices, id: \.self) { index in
                        let msg = vm.messages[index]

                        DiscordMessageItem(
                            vm: vm,
                            scheme: scheme,
                            messages: vm.messages,
                            index: index,
                            msg: msg,
                            chatId: chat.id
                        )
                        .id(msg.id)
                    }

                    typingIndicatorDiscordView()

                    Color.clear
                        .frame(height: 1)
                        .id("BOTTOM")
                        .onAppear { isAtBottom = true }
                        .onDisappear { isAtBottom = false }
                }
                .padding(.top, 8)
            }
            .background(DiscordTheme.bg(scheme).ignoresSafeArea())
            .onChange(of: vm.messages.count) { _ in
                // ✅ 과거 메시지 붙이는 중이면 튀지 않기
                if vm.isLoadingMore { return }

                // ✅ 유저가 바닥에 있을 때만 새 메시지 자동 스크롤
                if !isAtBottom { return }

                withAnimation(.easeOut(duration: 0.18)) {
                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                }

                // ✅ 바닥에 있을 때만 읽음 처리(원하면 유지)
                if let id = chat.id {
                    Task { await vm.markAsRead(courseId: id) }
                }
            }
        }
        .navigationTitle(chat.courseCode)
        .toolbarColorScheme(scheme == .dark ? .dark : .light, for: .navigationBar)
        .toolbarBackground(DiscordTheme.bg(scheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            discordInputBar
                .background(DiscordTheme.bg(scheme))
        }
        .onAppear {
            if let id = chat.id {
                Task {
                    await vm.loadUsername()
                    vm.startListening(courseId: id)
                    vm.startTypingListener(courseId: id)
                    vm.startReadStatusListener(courseId: id)
                    await vm.markAsRead(courseId: id)
                }
            }
        }
    }

    // MARK: - Typing Indicator

    @ViewBuilder
    private func typingIndicatorDiscordView() -> some View {
        let names = vm.typingUsers.values.map { $0.username }
        if !names.isEmpty {
            HStack(spacing: 8) {
                Text(typingText(names: names))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DiscordTheme.secondaryText(scheme))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func typingText(names: [String]) -> String {
        if names.count == 1 { return "\(names[0]) is typing..." }
        if names.count == 2 { return "\(names[0]) and \(names[1]) are typing..." }
        if names.count > 2 { return "\(names[0]) and \(names.count - 1) others are typing..." }
        return ""
    }

    // MARK: - Input Bar

    private var discordInputBar: some View {
        VStack(spacing: 8) {

            // Reply preview
            if let replying = vm.replyingTo {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DiscordTheme.secondaryText(scheme))
                        .frame(width: 3, height: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Replying to \(replying.senderName ?? "Unknown")")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DiscordTheme.secondaryText(scheme))

                        Text(replying.text)
                            .font(.system(size: 13))
                            .foregroundColor(DiscordTheme.primaryText(scheme))
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        vm.replyingTo = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DiscordTheme.secondaryText(scheme))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
            }

            HStack(spacing: 10) {

                Button { } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(DiscordTheme.secondaryText(scheme))
                }

                HStack(spacing: 10) {
                    TextField("Message...", text: $vm.messageText)
                        .foregroundColor(DiscordTheme.primaryText(scheme))
                        .onChange(of: vm.messageText) { _ in
                            if let id = chat.id {
                                Task { await vm.setTyping(courseId: id) }
                            }
                        }

                    Button { } label: {
                        Image(systemName: "face.smiling")
                            .foregroundColor(DiscordTheme.secondaryText(scheme))
                    }

                    Button { } label: {
                        Image(systemName: "mic")
                            .foregroundColor(DiscordTheme.secondaryText(scheme))
                    }

                    Button {
                        guard let id = chat.id else { return }
                        Task { await vm.sendMessage(courseId: id) }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(
                                vm.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? DiscordTheme.secondaryText(scheme)
                                : (scheme == .dark ? .white : .primary)
                            )
                    }
                    .disabled(vm.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(DiscordTheme.inputBg(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Discord Message Row

private struct DiscordMessageItem: View {

    let vm: CourseChatViewModel
    let scheme: ColorScheme

    let messages: [CourseMessage]
    let index: Int
    let msg: CourseMessage
    let chatId: String?

    // ✅ timestamp는 Date(비옵셔널)로 강제 통일
    private var ts: Date { msg.timestamp }
    private var prev: CourseMessage? { index > 0 ? messages[index - 1] : nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            if showDateSeparator {
                HStack {
                    Rectangle().fill(DiscordTheme.divider(scheme)).frame(height: 1)
                    Text(ts.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DiscordTheme.secondaryText(scheme))
                        .padding(.horizontal, 8)
                    Rectangle().fill(DiscordTheme.divider(scheme)).frame(height: 1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }

            HStack(alignment: .top, spacing: 12) {

                avatar

                VStack(alignment: .leading, spacing: 4) {
                    header

                    if let replyText = msg.replyToText, !replyText.isEmpty {
                        replyBlock(replyText: replyText, sender: msg.replyToSenderName)
                    }

                    Text(msg.text)
                        .font(.system(size: 16))
                        .foregroundColor(DiscordTheme.primaryText(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(rowBackground)
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    vm.replyingTo = msg
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }
            }
        }
        .onAppear {
            // ✅ 위에서 과거 메시지 로딩
            if index == 0, let id = chatId {
                vm.loadMoreMessages(courseId: id)
            }
        }
    }

    // MARK: - Grouping / separators

    private var isGrouped: Bool {
        guard let p = prev else { return false }
        let sameSender = p.senderId == msg.senderId
        let sameMinute = Calendar.current.isDate(p.timestamp, equalTo: ts, toGranularity: .minute)
        return sameSender && sameMinute
    }

    private var showDateSeparator: Bool {
        if index == 0 { return true }
        guard let p = prev else { return true }
        return !Calendar.current.isDate(ts, inSameDayAs: p.timestamp)
    }

    private var rowBackground: Color {
        isGrouped ? Color.clear : DiscordTheme.rowHighlight(scheme)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(msg.senderName ?? "Unknown")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DiscordTheme.primaryText(scheme))

            Text(ts, style: .time)
                .font(.system(size: 12))
                .foregroundColor(DiscordTheme.secondaryText(scheme))

            Spacer()
        }
        .opacity(isGrouped ? 0.0 : 1.0)
        .frame(height: isGrouped ? 0 : nil)
    }

    // MARK: - Avatar

    private var avatar: some View {
        Group {
            if isGrouped {
                Color.clear.frame(width: 40, height: 40)
            } else {
                avatarImage
            }
        }
    }

    private var avatarImage: some View {
        Group {
            if let user = vm.userCache[msg.senderId],
               let urlString = user.profileImageURL,
               let url = URL(string: urlString) {

                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholderAvatar
                }

            } else {
                placeholderAvatar
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }

    private var placeholderAvatar: some View {
        Circle()
            .fill(scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
            .overlay(
                Text(initials(from: msg.senderName))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DiscordTheme.secondaryText(scheme))
            )
    }

    // MARK: - Reply Block

    private func replyBlock(replyText: String, sender: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DiscordTheme.secondaryText(scheme))

            VStack(alignment: .leading, spacing: 2) {
                Text(sender ?? "Unknown")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DiscordTheme.secondaryText(scheme))

                Text(replyText)
                    .font(.system(size: 12))
                    .foregroundColor(DiscordTheme.secondaryText(scheme))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(DiscordTheme.replyBg(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func initials(from name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))" }
        return String(name.prefix(2))
    }
}
