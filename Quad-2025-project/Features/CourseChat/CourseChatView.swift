//
//  CourseChatView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import SwiftUI

struct CourseChatView: View {

    @StateObject var vm = CourseChatViewModel()
    @EnvironmentObject var chatListVM: CourseChatListViewModel
    let chat: CourseChat

    var body: some View {

        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {

                    let messages = vm.messages

                    ForEach(Array(zip(messages.indices, messages)), id: \.1.id) { index, msg in
                        MessageItem(
                            vm: vm,
                            messages: messages,
                            index: index,
                            msg: msg,
                            chatId: chat.id
                        )
                    }

                    // 🔥 Typing Indicator
                    typingIndicatorView()

                    Color.clear
                        .frame(height: 1)
                        .id("BOTTOM")
                }
                .padding(.bottom, 8)
            }
            .onChange(of: vm.shouldAutoScroll) { value in
                if value {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("BOTTOM", anchor: .bottom)
                    }
                    vm.shouldAutoScroll = false
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
                .background(.ultraThinMaterial)
        }
        .navigationTitle(chat.courseCode)
        .onAppear {
            if let id = chat.id {
                Task {
                    await vm.loadUsername()
                    vm.startListening(courseId: id)
                    vm.startTypingListener(courseId: id)
                    await vm.markAsRead(courseId: id)
                }
            }
        }
    }

    // MARK: - Input Bar

    var inputBar: some View {
        HStack(spacing: 10) {

            TextField("Message...", text: $vm.messageText)
                .onChange(of: vm.messageText) { _ in
                    if let id = chat.id {
                        Task { await vm.setTyping(courseId: id) }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(Capsule())

            Button {
                if let id = chat.id {
                    Task { await vm.sendMessage(courseId: id) }
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color("UTAustinOrange"))
                    .clipShape(Circle())
            }
        }
        .padding()
    }

    // MARK: - Typing Indicator

    @ViewBuilder
    func typingIndicatorView() -> some View {

        let names = vm.typingUsers.values.map { $0.username }

        if !names.isEmpty {
            HStack {
                Text(typingText(names: names))
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    func typingText(names: [String]) -> String {
        if names.count == 1 {
            return "\(names[0]) is typing..."
        } else if names.count == 2 {
            return "\(names[0]) and \(names[1]) are typing..."
        } else if names.count > 2 {
            return "\(names[0]) and \(names.count - 1) others are typing..."
        }
        return ""
    }
}

struct MessageItem: View {

    let vm: CourseChatViewModel
    let messages: [CourseMessage]
    let index: Int
    let msg: CourseMessage
    let chatId: String?

    var body: some View {

        VStack(spacing: 0) {

            if shouldShowDateSeparator {
                Text(msg.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 6)
            }

            messageRow
        }
        .onAppear {
            if index == 0, let id = chatId {
                vm.loadMoreMessages(courseId: id)
            }
        }
    }

    var shouldShowDateSeparator: Bool {
        if index == 0 { return true }

        return !Calendar.current.isDate(
            msg.timestamp,
            inSameDayAs: messages[index - 1].timestamp
        )
    }

    var messageRow: some View {

        let previousMessage = index > 0 ? messages[index - 1] : nil
        let showName = previousMessage?.senderId != msg.senderId

        return HStack(alignment: .bottom) {

            if msg.senderId != vm.uid {

                VStack(alignment: .leading, spacing: 4) {

                    if showName, let name = msg.senderName {
                        Text(name)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    Text(msg.text)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Spacer()

            } else {

                Spacer()

                Text(msg.text)
                    .padding(12)
                    .background(Color("UTAustinOrange"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal)
    }
}
