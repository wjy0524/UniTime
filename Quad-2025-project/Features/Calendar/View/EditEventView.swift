//
//  EditEventView.swift
//  Quad-2025-project
//
//  Created on Calendar Feature Enhancement
//


import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: EventViewModel

    let event: Event

    // MARK: - State
    @State private var title: String
    @State private var date: Date
    @State private var type: String
    @State private var location: String
    @State private var colorHex: String
    @State private var sharedWith: [String]
    @State private var reminderMinutes: Int?

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Options
    let eventTypes = [
        "General", "Meeting", "Deadline", "Class",
        "Social", "Personal", "Work", "Other"
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
        ("Gray", "#8E8E93")
    ]

    let reminderOptions: [(label: String, value: Int?)] = [
        ("None", nil),
        ("5 minutes before", 5),
        ("10 minutes before", 10),
        ("30 minutes before", 30),
        ("1 hour before", 60)
    ]

    // MARK: - Init
    init(event: Event, viewModel: EventViewModel) {
        self.event = event
        self.viewModel = viewModel

        _title = State(initialValue: event.title)
        _date = State(initialValue: event.date)
        _type = State(initialValue: event.type)
        _location = State(initialValue: event.location)
        _colorHex = State(initialValue: event.colorHex)
        _sharedWith = State(initialValue: event.sharedWith)
        _reminderMinutes = State(initialValue: event.reminderMinutes)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Edit Event")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveChanges() }
                            .disabled(title.isEmpty || isSaving)
                    }
                }
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
        }
    }

    // MARK: - Form Content
    private var formContent: some View {
        Form {
            eventDetailsSection
            colorSection
            reminderSection
            sharedSection
        }
    }

    // MARK: - Sections
    private var eventDetailsSection: some View {
        Section("Event Details") {
            TextField("Event Title", text: $title)

            DatePicker(
                "Date & Time",
                selection: $date,
                displayedComponents: [.date, .hourAndMinute]
            )

            Picker("Type", selection: $type) {
                ForEach(eventTypes, id: \.self) {
                    Text($0)
                }
            }

            TextField("Location (Optional)", text: $location)
        }
    }

    private var colorSection: some View {
        Section("Color") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(colorOptions, id: \.hex) { option in
                        Circle()
                            .fill(Color(hexStr: option.hex) ?? .orange)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle().stroke(
                                    colorHex == option.hex ? Color.primary : Color.clear,
                                    lineWidth: 3
                                )
                            )
                            .onTapGesture {
                                colorHex = option.hex
                            }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var reminderSection: some View {
        Section("Reminder") {
            Picker("Notify me", selection: $reminderMinutes) {
                ForEach(reminderOptions, id: \.label) { option in
                    Text(option.label)
                        .tag(option.value as Int?)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var sharedSection: some View {
        Group {
            if !sharedWith.isEmpty {
                Section("Shared With") {
                    ForEach(sharedWith, id: \.self) { uid in
                        SharedUserRow(uid: uid)
                    }
                }
            }
        }
    }

    // MARK: - Save
    private func saveChanges() {
        guard let eventId = event.id else { return }
        isSaving = true

        Task {
            do {
                try await viewModel.updateEvent(
                    eventId: eventId,
                    title: title,
                    date: date,
                    type: type,
                    location: location,
                    colorHex: colorHex,
                    reminderMinutes: reminderMinutes
                )

                let updatedEvent = Event(
                    id: eventId,
                    ownerId: event.ownerId,
                    title: title,
                    date: date,
                    type: type,
                    location: location,
                    colorHex: colorHex,
                    sharedWith: sharedWith,
                    reminderMinutes: reminderMinutes
                )

                NotificationManager.shared.removeNotification(for: updatedEvent)
                NotificationManager.shared.scheduleNotification(for: updatedEvent)

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
