//
//  ChatStore.swift
//우너재연
//

import Foundation
import SwiftUI

@MainActor
class ChatStore: ObservableObject {

    @Published var sessions: [ChatSession] = [] {
        didSet { saveSessions() }
    }

    @Published var currentSessionId: UUID? = nil

    private let storageKey = "ai_chat_sessions"

    // MARK: - Init
    init() {
        loadSessions()
    }

    // MARK: - Session Control

    /// ⚠️ 실제 메시지 입력 시에만 호출
    func createNewSessionIfNeeded() {
        guard currentSessionId == nil else { return }

        let newSession = ChatSession(
            title: "New Chat",
            messages: []
        )
        sessions.insert(newSession, at: 0)
        currentSessionId = newSession.id
    }

    func selectSession(_ session: ChatSession) {
        currentSessionId = session.id
    }

    /// 새 채팅 버튼 (임시 상태로만 전환)
    func startNewDraft() {
        currentSessionId = nil
    }

    // MARK: - Messages Binding

    var currentMessages: [AIChatMessage] {
        get {
            guard let id = currentSessionId else { return [] }
            return sessions.first(where: { $0.id == id })?.messages ?? []
        }
        set {
            guard
                let id = currentSessionId,
                let index = sessions.firstIndex(where: { $0.id == id })
            else { return }

            sessions[index].messages = newValue
        }
    }

    // MARK: - GPT-style Title Auto Generation

    func updateTitleIfNeeded(using message: String) {
        guard
            let id = currentSessionId,
            let index = sessions.firstIndex(where: { $0.id == id }),
            sessions[index].title == "New Chat"
        else { return }

        sessions[index].title = generateTitle(from: message)
    }

    private func generateTitle(from message: String) -> String {
        let cleaned = message
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let words = cleaned.split(separator: " ")
        return words.prefix(6).joined(separator: " ")
    }

    // MARK: - Persistence

    private func saveSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadSessions() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([ChatSession].self, from: data)
        else { return }

        sessions = decoded
    }
}

extension ChatStore {

    // 🗑 Delete
    func deleteSession(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
        if currentSessionId == session.id {
            currentSessionId = nil
        }
    }

    // ✏️ Rename
    func renameSession(_ session: ChatSession, to newTitle: String) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].title = newTitle
    }

    // 📌 Pin / Unpin
    func togglePin(_ session: ChatSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].isPinned.toggle()
        reorderSessions()
    }

    // 📌 핀된 항목 상단 고정
    private func reorderSessions() {
        sessions.sort { a, b in
            // 1️⃣ 핀된 게 항상 위
            if a.isPinned != b.isPinned {
                return a.isPinned && !b.isPinned
            }

            // 2️⃣ 같은 그룹 안에서는 기존 순서 유지
            let aIndex = sessions.firstIndex(where: { $0.id == a.id }) ?? 0
            let bIndex = sessions.firstIndex(where: { $0.id == b.id }) ?? 0
            return aIndex < bIndex
        }
    }
}


