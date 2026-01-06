//  AIChatListView.swift
//  Quad-2025-project
//

import SwiftUI

struct AIChatListView: View {

    @ObservedObject var chatStore: ChatStore
    let onClose: () -> Void
    @StateObject private var profileVM = ProfileViewModel()

    @State private var searchText = ""

    // Rename Alert
    @State private var showRenameAlert = false
    @State private var selectedSession: ChatSession?
    @State private var renameText = ""

    // MARK: - Search Filter (GPT-style)
    private var filteredSessions: [ChatSession] {
        if searchText.isEmpty {
            return chatStore.sessions
        }

        return chatStore.sessions.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Top Header
            VStack(alignment: .leading, spacing: 14) {

                // 🔹 Logo
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))

                    Text("AI Assistant")
                        .font(.system(size: 22, weight: .bold))
                }

                // 🔍 Search + New Chat
                HStack(spacing: 12) {

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search", text: $searchText)
                            .font(.system(size: 14))
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // ✏️ New Chat (아이콘만)
                    Button {
                        chatStore.startNewDraft()
                        onClose()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // MARK: - Chat History
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredSessions) { session in
                        Button {
                            chatStore.selectSession(session)
                            onClose()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {

                                HStack {
                                    Text(session.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    if session.isPinned {
                                        Image(systemName: "pin.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }

                                if let last = session.messages.last {
                                    Text(last.text)
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal)
                            .background(
                                chatStore.currentSessionId == session.id
                                ? Color(.systemGray5)
                                : Color.clear
                            )
                        }
                        // ⭐ GPT-style Long Press Menu
                        .contextMenu {
                            Button {
                                selectedSession = session
                                renameText = session.title
                                showRenameAlert = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }

                            Button {
                                chatStore.togglePin(session)
                            } label: {
                                Label(
                                    session.isPinned ? "Unpin" : "Pin",
                                    systemImage: session.isPinned ? "pin.slash" : "pin"
                                )
                            }

                            Button {
                                let url = URL(
                                    string: "https://quad.app/chat/\(session.id.uuidString)"
                                )!
                                ShareHelper.share(url: url)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive) {
                                chatStore.deleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        Divider()
                            .padding(.leading)
                    }
                }
                .padding(.top, 8)
            }

            Spacer()

            // MARK: - Profile
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(profileVM.username.prefix(2).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )

                // Username
                Text(profileVM.username)
                    .font(.system(size: 15, weight: .medium))

                Spacer()
            }
            .padding()
            .task {
                await profileVM.loadProfile(for: profileVM.myUid)
            }
            
        }
        .background(Color(.systemBackground))

        // MARK: - Rename Alert
        .alert("Rename Chat", isPresented: $showRenameAlert) {
            TextField("Title", text: $renameText)

            Button("Cancel", role: .cancel) {}

            Button("Save") {
                if let session = selectedSession {
                    chatStore.renameSession(session, to: renameText)
                }
            }
        }
    }
}

