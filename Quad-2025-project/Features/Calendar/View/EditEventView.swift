//
//  EditEventView.swift
//  Quad-2025-project
//
//  Created on Calendar Feature Enhancement
//

import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: EventViewModel

    let event: Event

    @State private var title: String
    @State private var date: Date
    @State private var type: String
    @State private var location: String
    @State private var colorHex: String
    @State private var sharedWith: [String]

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false

    let eventTypes = [
        "General", "Meeting", "Deadline", "Class", "Social", "Personal", "Work", "Other",
    ]

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

    init(event: Event, viewModel: EventViewModel) {
        self.event = event
        self.viewModel = viewModel

        _title = State(initialValue: event.title)
        _date = State(initialValue: event.date)
        _type = State(initialValue: event.type)
        _location = State(initialValue: event.location)
        _colorHex = State(initialValue: event.colorHex)
        _sharedWith = State(initialValue: event.sharedWith)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Event Details
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $title)
                        .font(.body)

                    DatePicker("Date & Time", selection: $date)

                    Picker("Type", selection: $type) {
                        ForEach(eventTypes, id: \.self) { eventType in
                            Text(eventType).tag(eventType)
                        }
                    }

                    TextField("Location (Optional)", text: $location)
                }

                // Color Selection
                Section(header: Text("Color")) {
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
                                                        ? Color.primary : Color.clear,
                                                    lineWidth: 3
                                                )
                                        )
                                        .onTapGesture {
                                            colorHex = option.hex
                                        }

                                    Text(option.name)
                                        .font(.caption2)
                                        .foregroundColor(
                                            colorHex == option.hex ? .primary : .secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Sharing Info
                if !sharedWith.isEmpty {
                    Section(header: Text("Shared With")) {
                        ForEach(sharedWith, id: \.self) { uid in
                            SharedUserRow(uid: uid)
                        }
                    }
                }

                // Event Info
                Section(header: Text("Event Information")) {
                    HStack {
                        Text("Created by")
                        Spacer()
                        Text(event.ownerId == viewModel.uid ? "You" : "Shared")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Event ID")
                        Spacer()
                        Text(event.id?.prefix(8) ?? "N/A")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty || isSaving)
                    .opacity(isSaving ? 0.6 : 1.0)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()

                        ProgressView("Saving...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                }
            }
        }
    }

    private func saveChanges() {
        guard !title.isEmpty else {
            errorMessage = "Event title is required"
            showError = true
            return
        }

        guard let eventId = event.id else {
            errorMessage = "Event ID not found"
            showError = true
            return
        }

        isSaving = true

        Task {
            do {
                try await viewModel.updateEvent(
                    eventId: eventId,
                    title: title,
                    date: date,
                    type: type,
                    location: location,
                    colorHex: colorHex
                )

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to update event: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

}

// Preview
#Preview {
    EditEventView(
        event: Event(
            id: "preview-id",
            ownerId: "user123",
            title: "Sample Event",
            date: Date(),
            type: "Meeting",
            location: "Conference Room",
            colorHex: "#FF6A00",
            sharedWith: []
        ),
        viewModel: EventViewModel()
    )
}
