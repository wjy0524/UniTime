
//
//  FriendRequestsView.swift
//  Quad-2025-project
//
//  View for managing incoming and outgoing friend requests
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - View Model (View 전용)

struct FriendRequestVM: Identifiable {
    let id: String            // friend_request document id
    let uid: String           // 상대방 uid
    let username: String
    let createdAt: Date
    let message: String?
}

// MARK: - Main View

struct FriendRequestsView: View {
    @ObservedObject var friendService: FriendService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedTab = 0
    @State private var receivedRequests: [FriendRequestVM] = []
    @State private var sentRequests: [FriendRequestVM] = []
    @State private var isLoading = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Picker("Requests", selection: $selectedTab) {
                    Text("Received (\(receivedRequests.count))").tag(0)
                    Text("Sent (\(sentRequests.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    if selectedTab == 0 {
                        receivedList
                    } else {
                        sentList
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("UTAustinOrange"))
                }
            }
            .task {
                await loadRequests()
            }
        }
    }

    // MARK: - Received

    private var receivedList: some View {
        Group {
            if receivedRequests.isEmpty {
                emptyState(text: "No Friend Requests")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(receivedRequests) { request in
                            ReceivedRequestCard(
                                request: request,
                                friendService: friendService
                            ) {
                                Task { await loadRequests() }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Sent

    private var sentList: some View {
        Group {
            if sentRequests.isEmpty {
                emptyState(text: "No Sent Requests")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sentRequests) { request in
                            SentRequestCard(
                                request: request,
                                friendService: friendService
                            ) {
                                Task { await loadRequests() }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Empty

    private func emptyState(text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.open")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            Text(text)
                .font(.title3)
                .bold()
            Text("Nothing to show here yet.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadRequests() async {
        isLoading = true
        await friendService.loadAll()

        receivedRequests = await buildRequests(
            uids: friendService.receivedRequests,
            isReceived: true
        )

        sentRequests = await buildRequests(
            uids: friendService.sentRequests,
            isReceived: false
        )

        isLoading = false
    }

    private func buildRequests(
        uids: [String],
        isReceived: Bool
    ) async -> [FriendRequestVM] {

        var result: [FriendRequestVM] = []

        for uid in uids {
            do {
                // user info
                let userSnap = try await db.collection("users").document(uid).getDocument()
                let username = userSnap.data()?["username"] as? String ?? "Unknown"

                // request info
                let query = db.collection("friend_requests")
                    .whereField(isReceived ? "fromUid" : "toUid", isEqualTo: uid)
                    .whereField(isReceived ? "toUid" : "fromUid", isEqualTo: friendService.myUid)

                let snap = try await query.getDocuments()
                guard let doc = snap.documents.first else { continue }

                let createdAt =
                    (doc["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                let message = doc["message"] as? String

                result.append(
                    FriendRequestVM(
                        id: doc.documentID,
                        uid: uid,
                        username: username,
                        createdAt: createdAt,
                        message: message
                    )
                )
            } catch {
                print("❌ Failed to load request:", error)
            }
        }
        return result
    }
}

// MARK: - Received Card

struct ReceivedRequestCard: View {
    let request: FriendRequestVM
    @ObservedObject var friendService: FriendService
    let onUpdate: () -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(request.username)
                .font(.headline)

            Text(relativeDate(request.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)

            if let message = request.message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if isProcessing {
                ProgressView()
            } else {
                HStack {
                    Button("Accept") {
                        isProcessing = true
                        Task {
                            await friendService.acceptRequest(from: request.uid)
                            isProcessing = false
                            onUpdate()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Decline") {
                        isProcessing = true
                        Task {
                            await friendService.cancelRequest(to: request.uid)
                            isProcessing = false
                            onUpdate()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Sent Card

struct SentRequestCard: View {
    let request: FriendRequestVM
    @ObservedObject var friendService: FriendService
    let onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(request.username)
                .font(.headline)

            Text("Pending")
                .font(.caption)
                .foregroundColor(.orange)

            Button("Cancel Request") {
                Task {
                    await friendService.cancelRequest(to: request.uid)
                    onUpdate()
                }
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Helpers

private func relativeDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}
