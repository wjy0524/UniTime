//
//  AddEventView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

//
//  AddEventView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import SwiftUI
import FirebaseAuth

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var type = ""
    @State private var location = ""
    @State private var colorHex: String = "#FF6A00"

    let onSave: (Event) -> Void

    // 색상 옵션 (EditEventView와 동일)
    let colorOptions: [(name: String, hex: String)] = [
        ("Orange", "#FF6A00"),
        ("Red", "#FF3B30"),
        ("Pink", "#FF2D55"),
        ("Purple", "#AF52DE"),
        ("Blue", "#007AFF"),
        ("Cyan", "#32ADE6"),
        ("Teal", "#30B0C7"),
        ("Green", "#34C759"),
        ("Yellow", "#FFCC00"),
        ("Gray", "#8E8E93"),
    ]

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Details
                Section("Details") {
                    TextField("Title", text: $title)

                    DatePicker(
                        "Date & Time",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    TextField("Type", text: $type)
                    TextField("Location", text: $location)
                }

                // MARK: - Color
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(colorOptions, id: \.hex) { option in
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hexStr: option.hex) ?? .orange)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    colorHex == option.hex
                                                        ? Color.primary
                                                        : Color.clear,
                                                    lineWidth: 3
                                                )
                                        )
                                        .onTapGesture {
                                            colorHex = option.hex
                                        }

                                    Text(option.name)
                                        .font(.caption2)
                                        .foregroundColor(
                                            colorHex == option.hex
                                                ? .primary
                                                : .secondary
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // Cancel
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                // Save
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Save
    private func saveEvent() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let newEvent = Event(
            ownerId: uid,
            title: title.trimmingCharacters(in: .whitespaces),
            date: date,
            type: type.isEmpty ? "General" : type,
            location: location,
            colorHex: colorHex,
            sharedWith: []
        )

        onSave(newEvent)
        dismiss()
    }
}
