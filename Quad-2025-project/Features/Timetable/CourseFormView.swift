//
//  CourseFormView.swift
//  Quad-2025-project
//
//  Created on Timetable Feature Enhancement
//

import SwiftUI

struct CourseFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TimetableViewModel

    var courseToEdit: TimetableCourse?
    var isEditMode: Bool { courseToEdit != nil }

    // Form fields
    @State private var name: String = ""
    @State private var code: String = ""
    @State private var instructor: String = ""
    @State private var location: String = ""
    @State private var selectedColor: Color = .blue
    @State private var courseTimes: [CourseTime] = []
    @State private var showingAddTimeSheet = false

    let availableColors: [Color] = [
        .blue, .green, .purple, .orange, .red, .pink, .cyan, .indigo, .teal, .mint,
    ]

    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

    init(viewModel: TimetableViewModel, courseToEdit: TimetableCourse? = nil) {
        self.viewModel = viewModel
        self.courseToEdit = courseToEdit

        if let course = courseToEdit {
            _name = State(initialValue: course.name)
            _code = State(initialValue: course.code)
            _instructor = State(initialValue: course.instructor)
            _location = State(initialValue: course.location)
            _selectedColor = State(initialValue: course.color)
            _courseTimes = State(initialValue: course.times)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("Course Information")) {
                    TextField("Course Name", text: $name)
                    TextField("Course Code", text: $code)
                    TextField("Instructor", text: $instructor)
                    TextField("Location", text: $location)
                }

                // Color Selection
                Section(header: Text("Color")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color.primary,
                                                lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Course Times
                Section(header: Text("Class Times")) {
                    if courseTimes.isEmpty {
                        Text("No class times added")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(courseTimes) { time in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(days[time.day])
                                        .font(.subheadline)
                                        .bold()
                                    Text(
                                        "\(formatTime(time.startTime)) - \(formatTime(time.endTime))"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(role: .destructive) {
                                    courseTimes.removeAll { $0.id == time.id }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    Button {
                        showingAddTimeSheet = true
                    } label: {
                        Label("Add Time Slot", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Course" : "Add Course")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Save" : "Add") {
                        saveCourse()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingAddTimeSheet) {
                AddTimeSlotView(courseTimes: $courseTimes)
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !code.isEmpty && !courseTimes.isEmpty
    }

    private func saveCourse() {
        let course = TimetableCourse(
            id: courseToEdit?.id ?? UUID(),
            name: name,
            code: code,
            instructor: instructor,
            location: location,
            colorHex: selectedColor.toHex(),
            times: courseTimes
        )

        if isEditMode {
            viewModel.updateCourse(course)
        } else {
            viewModel.addCourse(course)
        }

        dismiss()
    }

    private func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", displayHour, minute, suffix)
    }
}

// MARK: - Add Time Slot View
struct AddTimeSlotView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var courseTimes: [CourseTime]

    @State private var selectedDay: Int = 0
    @State private var startHour: Int = 9
    @State private var startMinute: Int = 0
    @State private var endHour: Int = 10
    @State private var endMinute: Int = 0

    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    let hours = Array(0...23)
    let minutes = [0, 15, 30, 45]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Day")) {
                    Picker("Day", selection: $selectedDay) {
                        ForEach(0..<days.count, id: \.self) { index in
                            Text(days[index]).tag(index)
                        }
                    }
                    #if os(iOS)
                        .pickerStyle(.wheel)
                    #endif
                }

                Section(header: Text("Start Time")) {
                    HStack {
                        Picker("Hour", selection: $startHour) {
                            ForEach(hours, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        #if os(iOS)
                            .pickerStyle(.wheel)
                        #endif
                        .frame(maxWidth: .infinity)

                        Picker("Minute", selection: $startMinute) {
                            ForEach(minutes, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        #if os(iOS)
                            .pickerStyle(.wheel)
                        #endif
                        .frame(maxWidth: .infinity)
                    }
                }

                Section(header: Text("End Time")) {
                    HStack {
                        Picker("Hour", selection: $endHour) {
                            ForEach(hours, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        #if os(iOS)
                            .pickerStyle(.wheel)
                        #endif
                        .frame(maxWidth: .infinity)

                        Picker("Minute", selection: $endMinute) {
                            ForEach(minutes, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        #if os(iOS)
                            .pickerStyle(.wheel)
                        #endif
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Add Time Slot")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTimeSlot()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        return endMinutes > startMinutes
    }

    private func addTimeSlot() {
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        let courseTime = CourseTime(
            day: selectedDay,
            startTime: startMinutes,
            endTime: endMinutes
        )

        courseTimes.append(courseTime)
        dismiss()
    }

    private func formatHour(_ hour: Int) -> String {
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        return "\(displayHour) \(suffix)"
    }
}
