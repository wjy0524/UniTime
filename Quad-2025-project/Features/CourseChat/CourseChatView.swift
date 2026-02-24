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
                VStack(spacing: 2) {
                    
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
            .onChange(of: vm.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                }
                if let id = chat.id {
                        Task {
                            await vm.markAsRead(courseId: id)
                        }
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
                    vm.startReadStatusListener(courseId: id)
                    await vm.markAsRead(courseId: id)
                }
            }
        }
    }

    // MARK: - Input Bar

    var inputBar: some View {
        HStack(spacing: 8) {

            TextField("Message...", text: $vm.messageText)
                .onChange(of: vm.messageText) { _ in
                    if let id = chat.id {
                        Task { await vm.setTyping(courseId: id) }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                if let id = chat.id {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                    Task {
                        await vm.sendMessage(courseId: id)
                    }
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        vm.messageText.isEmpty
                        ? Color.gray
                        : Color("UTAustinOrange")
                    )
                    .clipShape(Circle())
            }
            .disabled(vm.messageText.isEmpty)
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
    
    var isLastMessage: Bool {
        index == messages.count - 1
    }

    var isReadByAll: Bool {

        guard isLastMessage else { return false }

        let myIndex = msg.messageIndex

        // 나 제외한 모든 유저
        let others = vm.readStatusMap.filter { $0.key != vm.uid }

        if others.isEmpty { return false }

        return others.allSatisfy { $0.value >= myIndex }
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

        var isGrouped: Bool {
            guard let previous = previousMessage else { return false }

            let sameSender = previous.senderId == msg.senderId

            let sameMinute =
                Calendar.current.isDate(
                    previous.timestamp,
                    equalTo: msg.timestamp,
                    toGranularity: .minute
                )

            return sameSender && sameMinute
        }
        let showName = previousMessage?.senderId != msg.senderId
        

        return HStack(alignment: .bottom, spacing: 8) {

            if msg.senderId != vm.uid {

                // 🔥 LEFT MESSAGE

                if showName {
                    profileImageView
                } else {
                    Spacer().frame(width: 32)
                }

                VStack(alignment: .leading, spacing: isGrouped ? 1 : 6) {

                    if showName, let name = msg.senderName {
                        Text(name)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: isGrouped ? 1 : 6) {

                        Text(msg.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.03), radius: 2)

                        if !isGrouped {
                            Text(msg.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

            } else {

                // 🔥 RIGHT MESSAGE

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {

                    Text(msg.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("UTAustinOrange"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.05), radius: 2)

                    if !isGrouped {
                        Text(msg.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    // 🔥 그룹 여부와 상관없이 마지막이면 표시
                    if isLastMessage {
                        Text(isReadByAll ? "Read" : "Sent")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    var profileImageView: some View {
        Group {
            if let user = vm.userCache[msg.senderId],
               let urlString = user.profileImageURL,
               let url = URL(string: urlString) {

                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                }
            } else {
                Circle()
                    .fill(Color.gray)
                    .overlay(
                        Text(initials(from: msg.senderName))
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
    
    func initials(from name: String?) -> String {
        guard let name = name else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2))
    }
}
