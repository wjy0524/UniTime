//
//  SharedTimetablesView.swift
//  Quad-2025-project
//
//  Created for viewing accepted shared timetables
//

import FirebaseAuth
import SwiftUI

struct SharedTimetablesView: View {
    @StateObject private var shareViewModel = TimetableShareViewModel.shared
    @State private var sharedTimetables: [TimetableShareRequest] = []
    @State private var isLoading: Bool = true
    @State private var selectedTimetable: TimetableShareRequest?
    @State private var timetableToDelete: TimetableShareRequest?
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading shared timetables...")
                } else if sharedTimetables.isEmpty {
                    emptyStateView
                } else {
                    sharedTimetablesList
                }
            }
            .navigationTitle("Shared Timetables")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSharedTimetables()
            }
            .sheet(item: $selectedTimetable) { timetable in
                TimetableDetailView(
                    shareRequest: timetable,
                    onDelete: {
                        timetableToDelete = timetable
                        showingDeleteConfirmation = true
                    })
            }
            .alert("Remove Shared Timetable", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if let timetable = timetableToDelete {
                        deleteSharedTimetable(timetable)
                    }
                }
            } message: {
                if let timetable = timetableToDelete {
                    Text(
                        "Are you sure you want to remove \(timetable.fromUsername)'s shared timetable? This cannot be undone."
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Shared Timetables")
                .font(.title2)
                .bold()

            Text("When someone shares their timetable with you and you accept, it will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Shared Timetables List

    var sharedTimetablesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(sharedTimetables) { timetable in
                    SharedTimetableCard(timetable: timetable) {
                        selectedTimetable = timetable
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            timetableToDelete = timetable
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Load Shared Timetables

    func loadSharedTimetables() {
        isLoading = true
        shareViewModel.getSharedTimetables { timetables in
            DispatchQueue.main.async {
                self.sharedTimetables = timetables
                self.isLoading = false
            }
        }
    }

    // MARK: - Delete Shared Timetable

    func deleteSharedTimetable(_ timetable: TimetableShareRequest) {
        guard let requestId = timetable.id else { return }

        isLoading = true
        shareViewModel.removeSharedTimetable(requestId) { success in
            DispatchQueue.main.async {
                if success {
                    self.sharedTimetables.removeAll { $0.id == requestId }
                }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Shared Timetable Card

struct SharedTimetableCard: View {
    let timetable: TimetableShareRequest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    if let imageURL = timetable.fromUserProfileImage,
                        let url = URL(string: imageURL)
                    {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(timetable.fromUsername.prefix(1).uppercased()))
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(timetable.fromUsername)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Shared \(timeAgo(timetable.timestamp))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }

                Divider()

                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(Color("UTAustinOrange"))

                    Text(
                        "\(timetable.timetableCourses.count) course\(timetable.timetableCourses.count == 1 ? "" : "s")"
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Spacer()

                    Text("View Details")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8)
        }
        .buttonStyle(.plain)
    }

    func timeAgo(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "just now"
        }
    }
}

// MARK: - Timetable Detail View

struct TimetableDetailView: View {
    let shareRequest: TimetableShareRequest
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    let hours = Array(8...21)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    userInfoHeader

                    timetableGrid

                    courseList
                }
                .padding()
            }
            .navigationTitle("\(shareRequest.fromUsername)'s Timetable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    // MARK: - User Info Header

    var userInfoHeader: some View {
        HStack(spacing: 16) {
            if let imageURL = shareRequest.fromUserProfileImage,
                let url = URL(string: imageURL)
            {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Text(String(shareRequest.fromUsername.prefix(1).uppercased()))
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(shareRequest.fromUsername)
                    .font(.title3)
                    .bold()

                Text("\(shareRequest.timetableCourses.count) Courses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Timetable Grid

    var timetableGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Schedule")
                .font(.headline)
                .padding(.horizontal)

            GeometryReader { geometry in
                let timeColumnWidth: CGFloat = 50
                let availableWidth = geometry.size.width - timeColumnWidth
                let columnWidth = availableWidth / 5

                ScrollView {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Text("Time")
                                .frame(width: timeColumnWidth)
                                .font(.caption)

                            ForEach(days, id: \.self) { day in
                                Text(day)
                                    .font(.caption)
                                    .frame(width: columnWidth)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))

                        ForEach(hours, id: \.self) { hour in
                            HStack(spacing: 0) {
                                Text(timeString(hour))
                                    .frame(width: timeColumnWidth)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                ForEach(0..<5, id: \.self) { dayIndex in
                                    ZStack {
                                        Rectangle()
                                            .stroke(Color.gray.opacity(0.2))
                                            .background(Color(white: 1.0))

                                        courseBlocks(
                                            day: dayIndex, hour: hour, columnWidth: columnWidth)
                                    }
                                    .frame(width: columnWidth, height: 60)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 600)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    func courseBlocks(day: Int, hour: Int, columnWidth: CGFloat) -> some View {
        let coursesAtHour = shareRequest.timetableCourses.filter { course in
            course.times.contains { time in
                time.day == day && hour >= (time.startTime / 60) && hour < (time.endTime / 60)
            }
        }

        return ForEach(coursesAtHour) { course in
            if let time = course.times.first(where: { $0.day == day }) {
                let duration = CGFloat(time.endTime - time.startTime) / 60

                VStack(alignment: .leading, spacing: 1) {
                    Text(course.code)
                        .bold()
                        .font(.system(size: min(columnWidth * 0.12, 11)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(course.name)
                        .font(.system(size: min(columnWidth * 0.1, 9)))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(course.location)
                        .font(.system(size: min(columnWidth * 0.09, 8)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .opacity(0.8)
                }
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: duration * 60)
                .background((Color(hexStr: course.colorHex) ?? .blue).opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(4)
            }
        }
    }

    // MARK: - Course List

    var courseList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course Details")
                .font(.headline)
                .padding(.horizontal)

            ForEach(shareRequest.timetableCourses) { course in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color(hexStr: course.colorHex) ?? .blue)
                            .frame(width: 12, height: 12)

                        Text(course.code)
                            .font(.headline)

                        Spacer()
                    }

                    Text(course.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !course.instructor.isEmpty {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.caption)
                            Text(course.instructor)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    if !course.location.isEmpty {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                            Text(course.location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    if !course.times.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(course.times) { time in
                                HStack(spacing: 4) {
                                    Text(dayName(time.day))
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color("UTAustinOrange").opacity(0.2))
                                        .cornerRadius(4)

                                    Text(formatTimeMinutes(time.startTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("-")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatTimeMinutes(time.endTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
        }
    }

    // MARK: - Helper Functions

    func timeString(_ hour: Int) -> String {
        let display = hour == 12 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        return "\(display) \(suffix)"
    }

    func formatTimeMinutes(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour <= 12 ? hour : hour - 12)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    func dayName(_ dayIndex: Int) -> String {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        guard dayIndex >= 0 && dayIndex < dayNames.count else { return "" }
        return dayNames[dayIndex]
    }
}

// MARK: - Preview

struct SharedTimetablesView_Previews: PreviewProvider {
    static var previews: some View {
        SharedTimetablesView()
    }
}
