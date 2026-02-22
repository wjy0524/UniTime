//
//  CourseChatView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import SwiftUI

struct CourseChatView: View {

    @StateObject var vm = CourseChatViewModel()
    let chat: CourseChat

    var body: some View {
        VStack(spacing: 0) {

            // 🔹 메시지 리스트
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(vm.messages) { msg in
                            messageRow(msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last?.id {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // 🔹 입력창
            HStack(spacing: 10) {
                TextField("Message...", text: $vm.messageText)
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
            .background(.ultraThinMaterial)
        }
        .navigationTitle(chat.courseCode)
        .ignoresSafeArea(.keyboard, edges: .bottom)   // 🔥 키보드 대응
        .onAppear {
            if let id = chat.id {
                Task {
                    await vm.loadUsername()   // 🔥 반드시 먼저
                    vm.startListening(courseId: id)
                    await vm.markAsRead(courseId: id)
                }
            }
        }    }

    // MARK: - Message Row

    func messageRow(_ msg: CourseMessage) -> some View {
        HStack(alignment: .bottom) {

            if msg.senderId != vm.uid {

                VStack(alignment: .leading, spacing: 4) {

                    if let name = msg.senderName {
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
