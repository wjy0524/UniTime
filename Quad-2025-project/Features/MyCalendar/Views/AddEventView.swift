//
//  AddEventView.swift
//  미국 에타
//
//  Created by Isaac Choi on 9/11/25.
//

import Foundation
import SwiftUI
import UIKit

// AddEventView.swift

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    
    // State variables
    @State private var title: String
    @State private var location: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var color: Color
    @State private var repeatDays: Set<Int>
    @State private var reminderMinutesBefore: Int?
    @State private var repeatEndDate: Date?
    @State private var hasRepeatEndDate: Bool
    
    // 🔑 new state for "Repeat" toggle
    @State private var isRepeating: Bool

    private let currentWeekday: Int // Sunday=1, Monday=2...

    var onSave: (EventModel) -> Void

    init(
        title: String = "",
        location: String = "",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(3600),
        color: Color = .blue,
        repeatDays: Set<Int> = [],
        reminderMinutesBefore: Int? = nil,
        repeatEndDate: Date? = nil,
        onSave: @escaping (EventModel) -> Void
    ) {
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        
        self._title = State(initialValue: title)
        self._location = State(initialValue: location)
        self._startDate = State(initialValue: startDate)
        self._endDate = State(initialValue: endDate)
        self._color = State(initialValue: color)
        
        // 🔑 If repeatDays is empty, default to today
        let initialRepeatDays = repeatDays.isEmpty ? [todayWeekday] : repeatDays
        self._repeatDays = State(initialValue: initialRepeatDays)
        
        self._reminderMinutesBefore = State(initialValue: reminderMinutesBefore)
        self._repeatEndDate = State(initialValue: repeatEndDate)
        self._hasRepeatEndDate = State(initialValue: repeatEndDate != nil)
        
        // 🔑 Toggle on if repeatDays was provided
        self._isRepeating = State(initialValue: !repeatDays.isEmpty)
        
        self.currentWeekday = todayWeekday
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Title & Location
                Section("Title & Location") {
                    TextField("Event Title", text: $title)
                    TextField("Location", text: $location)
                }

                // MARK: - Date & Time
                Section("Date & Time") {
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)
                }

                // MARK: - Repeat
                Section("Repeat") {
                    Toggle("Repeat this event", isOn: $isRepeating)
                }

                if isRepeating {
                    Section("Repeat Days") {
                        WeekdayPickerView(selectedDays: $repeatDays, currentWeekday: currentWeekday)
                    }

                    Section("Repeat End") {
                        Toggle("Set End Date", isOn: $hasRepeatEndDate)
                            .onChange(of: hasRepeatEndDate) { newValue in
                                if newValue && repeatEndDate == nil {
                                    repeatEndDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                                }
                            }

                        if hasRepeatEndDate {
                            DatePicker(
                                "Until",
                                selection: Binding(
                                    get: { repeatEndDate ?? Date() },
                                    set: { repeatEndDate = $0 }
                                ),
                                in: Calendar.current.date(byAdding: .day, value: 1, to: Date())!...,
                                displayedComponents: .date
                            )
                        }
                    }
                }
                
                // MARK: - Color
                Section("Color") {
                    ColorPicker("Event Color", selection: $color)
                }

                // MARK: - Reminder
                Section("Reminder") {
                    Picker("Alert", selection: $reminderMinutesBefore) {
                        Text("None").tag(nil as Int?)
                        Text("5 minutes before").tag(5 as Int?)
                        Text("10 minutes before").tag(10 as Int?)
                        Text("15 minutes before").tag(15 as Int?)
                        Text("30 minutes before").tag(30 as Int?)
                        Text("1 hour before").tag(60 as Int?)
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Add Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let model = EventModel(
                            title: title,
                            location: location.isEmpty ? nil : location,
                            startDate: startDate,
                            endDate: endDate,
                            color: UIColor(color),
                            repeatDays: isRepeating ? repeatDays : [],
                            reminderMinutesBefore: reminderMinutesBefore,
                            repeatEndDate: isRepeating && hasRepeatEndDate ? repeatEndDate : nil
                        )
                        onSave(model)
                        dismiss()
                    }
                }
            }
        }
    }
}
