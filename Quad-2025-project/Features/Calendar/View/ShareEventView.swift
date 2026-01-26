
//
//  ShareEventView.swift
//  Quad-2025-project
//

//
//  ShareEventView.swift
//  Quad-2025-project
//

import Kingfisher
import SwiftUI

struct ShareEventView: View {
    let event: Event
    @ObservedObject var viewModel: EventViewModel

    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendService = FriendService.shared

    @State private var selectedFriend: String?
    @State private var isSending = false
    @State private var hasSent = false

    var body: some View {
        NavigationStack {
            List {
                Section("Share with") {
                    if friendService.friends.isEmpty {
                        Text("You don't have any friends yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(friendService.friends, id: \.self) { uid in
                            FriendShareRow(
                                uid: uid,
                                isSelected: selectedFriend == uid
                            ) {
                                selectedFriend = uid
                            }
                        }
                    }
                }
            }
            .navigationTitle("Share Event")
            .toolbar {

                // Cancel
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                // Share (send request)
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSending ? "Sending..." : "Send Request") {
                        sendRequest()
                    }
                    .disabled(selectedFriend == nil || isSending)
                }
            }
            .task {
                await friendService.loadAll()
            }
        }
    }

    // MARK: - Send Share Request
    private func sendRequest() {
        guard let targetUID = selectedFriend else { return }
        guard !hasSent else { return }   // 🔥 핵심

        hasSent = true
        isSending = true

        Task {
            await viewModel.sendEventShareRequest(
                event: event,
                to: targetUID
            )

            await MainActor.run {
                isSending = false
                dismiss()
            }
        }
    }
}



struct FriendShareRow: View {
    let uid: String
    let isSelected: Bool
    let onTap: () -> Void

    @StateObject private var profileVM: ProfileViewModel

    init(
        uid: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) {
        self.uid = uid
        self.isSelected = isSelected
        self.onTap = onTap
        _profileVM = StateObject(
            wrappedValue: ProfileViewModel(uid: uid)
        )
    }

    var body: some View {
        HStack(spacing: 12) {

            if let url = URL(string: profileVM.profileImageURL),
               !profileVM.profileImageURL.isEmpty {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.9))
                    )
            }

            VStack(alignment: .leading) {
                Text(profileVM.username)
                    .font(.headline)
                Text("@\(uid)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
