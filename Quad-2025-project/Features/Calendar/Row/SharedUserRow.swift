//
//  SharedUserRow.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/25/26.
//

import SwiftUI

struct SharedUserRow: View {
    let uid: String
    @StateObject private var profileVM: ProfileViewModel

    init(uid: String) {
        self.uid = uid
        _profileVM = StateObject(
            wrappedValue: ProfileViewModel(uid: uid)
        )
    }

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(.secondary)

            Text(
                profileVM.username.isEmpty
                    ? "Loading..."
                    : profileVM.username
            )
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}
