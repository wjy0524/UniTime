//
//  EventShareRequestRow.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/25/26.
//

import SwiftUI

struct EventShareRequestRow: View {
    let req: EventShareRequest
    let vm: EventShareRequestViewModel

    @StateObject private var profileVM: ProfileViewModel
    @State private var isProcessing = false

    init(req: EventShareRequest, vm: EventShareRequestViewModel) {
        self.req = req
        self.vm = vm
        _profileVM = StateObject(
            wrappedValue: ProfileViewModel(uid: req.fromUid)
        )
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    profileVM.username.isEmpty
                        ? "Loading..."
                        : profileVM.username
                )
                .font(.headline)

                Text(isProcessing ? "Processing..." : "Pending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Accept") {
                handleAccept()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)   // ✅ 이거 추가

            Button("Decline") {
                handleDecline()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(isProcessing)
        }
        .opacity(isProcessing ? 0.6 : 1.0)
    }

    // MARK: - Actions
    private func handleAccept() {
        guard !isProcessing, let id = req.id else { return }
        isProcessing = true

        Task {
            await vm.accept(requestId: id)
            await MainActor.run { isProcessing = false }
        }
    }

    private func handleDecline() {
        guard !isProcessing, let id = req.id else { return }
        isProcessing = true

        Task {
            await vm.decline(requestId: id)
            await MainActor.run { isProcessing = false }
        }
    }

}
