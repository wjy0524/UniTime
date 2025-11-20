//
//  AddEventView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import SwiftUI
import FirebaseAuth

struct AddEventView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var date = Date()
    @State private var type = ""
    @State private var location = ""
    let onSave: (Event) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Type", text: $type)
                    TextField("Location", text: $location)
                }
            }
            .navigationTitle("Add Event")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

                        if let uid = Auth.auth().currentUser?.uid {
                            let newEvent = Event(
                                ownerId: uid,
                                title: title,
                                date: date,
                                type: type.isEmpty ? "General" : type,
                                location: location,
                                colorHex: "#FF6A00",
                                sharedWith: []   // 🔥 필수!!
                            )
                            onSave(newEvent)
                            dismiss()
                        }                    }

                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
