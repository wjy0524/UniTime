//
//  TimetableView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

//
//  TimetableView.swift
//  Quad-2025-project
//

import SwiftUI

struct CourseTime: Identifiable {
    let id = UUID()
    let day: Int          // 0–4 (Mon–Fri)
    let startTime: Int    // minutes from midnight
    let endTime: Int      // minutes from midnight
}

struct CourseItem: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    let instructor: String
    let location: String
    let color: Color
    let times: [CourseTime]
}

struct TimetableView: View {

    // --------------------------
    // MOCK COURSES (Matches React)
    // --------------------------
    let courses: [CourseItem] = [
        CourseItem(
            name: "Data Structures",
            code: "CS301",
            instructor: "Dr. Smith",
            location: "ENG 204",
            color: .blue,
            times: [
                CourseTime(day: 0, startTime: 540, endTime: 630),
                CourseTime(day: 2, startTime: 540, endTime: 630)
            ]
        ),
        CourseItem(
            name: "Calculus II",
            code: "MATH202",
            instructor: "Prof. Johnson",
            location: "MATH 101",
            color: .green,
            times: [
                CourseTime(day: 0, startTime: 660, endTime: 750),
                CourseTime(day: 2, startTime: 660, endTime: 750),
                CourseTime(day: 4, startTime: 660, endTime: 750)
            ]
        ),
        CourseItem(
            name: "Physics Lab",
            code: "PHYS201",
            instructor: "Dr. Lee",
            location: "SCI 305",
            color: .purple,
            times: [
                CourseTime(day: 2, startTime: 840, endTime: 1020)
            ]
        ),
        CourseItem(
            name: "English Literature",
            code: "ENG105",
            instructor: "Prof. Davis",
            location: "HUM 150",
            color: .orange,
            times: [
                CourseTime(day: 1, startTime: 780, endTime: 870),
                CourseTime(day: 3, startTime: 780, endTime: 870)
            ]
        )
    ]
    
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    let hours = Array(8...21) // 8 AM → 9 PM (14 hours)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Header
                HStack {
                    Text("My Timetable")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button {
                        // TODO: Add Course Action
                    } label: {
                        Label("Add", systemImage: "plus")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                // Timetable grid
                ScrollView(.horizontal) {
                    timetableGrid
                        .padding(.horizontal)
                }

                // Course List
                courseList
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("Timetable")
    }
}

extension TimetableView {

    // --------------------------
    // TIMETABLE GRID
    // --------------------------
    var timetableGrid: some View {
        VStack(spacing: 0) {

            // Days header
            HStack(spacing: 2) {
                Text("Time")
                    .frame(width: 60)

                ForEach(days, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 8)

            // Rows by hour
            ForEach(hours, id: \.self) { hour in
                HStack(spacing: 2) {
                    timeLabel(hour)

                    ForEach(0..<5) { dayIndex in
                        ZStack {
                            Rectangle()
                                .stroke(Color.gray.opacity(0.2))

                            courseBlocks(day: dayIndex, hour: hour)
                        }
                        .frame(height: 60)
                    }
                }
            }
        }
    }

    // Time Label
    func timeLabel(_ hour: Int) -> some View {
        Text(formatHour(hour))
            .frame(width: 60)
            .font(.caption)
            .foregroundColor(.secondary)
    }

    // Format hour into AM/PM
    func formatHour(_ hour: Int) -> String {
        let display = hour == 12 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        return "\(display) \(suffix)"
    }

    // --------------------------
    // CLASS BLOCKS PER SLOT
    // --------------------------
    func courseBlocks(day: Int, hour: Int) -> some View {
        let inThisHour = courses.filter { course in
            course.times.contains { t in
                t.day == day && hour == t.startTime / 60
            }
        }

        return ForEach(inThisHour) { course in
            if let time = course.times.first(where: { $0.day == day }) {
                let duration = CGFloat(time.endTime - time.startTime) / 60

                VStack(alignment: .leading, spacing: 2) {
                    Text(course.code)
                        .bold()
                        .font(.caption)
                    Text(course.name)
                        .font(.caption2)
                    Text(course.location)
                        .font(.caption2)
                        .opacity(0.8)
                }
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: duration * 60)   // 60px per hour
                .background(course.color.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
    }
}

extension TimetableView {

    // --------------------------
    // COURSE LIST
    // --------------------------
    var courseList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enrolled Courses")
                .font(.headline)
                .padding(.horizontal)

            ForEach(courses) { course in
                HStack(spacing: 12) {
                    Circle()
                        .fill(course.color)
                        .frame(width: 14, height: 14)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(course.code) - \(course.name)")
                            .font(.subheadline)

                        Text("\(course.instructor) • \(course.location)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Edit") {}
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}
