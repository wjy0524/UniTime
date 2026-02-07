//
//  TimetableView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct TimetableView: View {
    @StateObject private var viewModel = TimetableViewModel()
    @State private var showingImportOptions = false
    @State private var showingFileImporter = false
    @State private var importType: ImportType = .json
    @State private var selectedTimeSlot: TimeSlot?
    @State private var showingShareSearch = false
    @State private var showingShareRequests = false
    @State private var showingSharedTimetables = false
    @StateObject private var shareViewModel = TimetableShareViewModel.shared

    enum ImportType {
        case json, csv
    }

    struct TimeSlot {
        let day: Int
        let hour: Int
    }

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    let hours = Array(8...21)  // 8 AM → 9 PM (14 hours)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Header
                HStack {
                    Text("My Timetable")
                        .font(.title2)
                        .bold()

                    Spacer()

                    // View Shared Timetables Button
                    Button {
                        showingSharedTimetables = true
                    } label: {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("UTAustinOrange"))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                            )
                    }
                    .buttonStyle(.plain)

                    // Share Requests Button
                    Button {
                        showingShareRequests = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("UTAustinOrange"))
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                                )

                            if shareViewModel.shareRequests.count > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 18, height: 18)

                                    Text("\(min(shareViewModel.shareRequests.count, 99))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Menu {
                        Button {
                            viewModel.showingAddSheet = true
                        } label: {
                            Label("Add Course Manually", systemImage: "plus")
                        }

                        Button {
                            showingImportOptions = true
                        } label: {
                            Label("Import from File", systemImage: "square.and.arrow.down")
                        }

                        if !viewModel.courses.isEmpty {
                            Button {
                                showingShareSearch = true
                            } label: {
                                Label("Share Timetable", systemImage: "person.2.fill")
                            }

                            Divider()

                            Menu {
                                Button {
                                    exportJSON()
                                } label: {
                                    Label("Export as JSON", systemImage: "doc.text")
                                }

                                Button {
                                    exportCSV()
                                } label: {
                                    Label("Export as CSV", systemImage: "tablecells")
                                }
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive) {
                                viewModel.clearAll()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        }
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

                // Empty State or Timetable grid
                if viewModel.courses.isEmpty {
                    emptyStateView
                } else {
                    timetableGrid
                        .padding(.horizontal)

                    // Course List
                    courseList
                }
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("Timetable")
        .sheet(isPresented: $viewModel.showingAddSheet) {
            CourseFormView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            if let course = viewModel.selectedCourse {
                CourseFormView(viewModel: viewModel, courseToEdit: course)
            }
        }
        .confirmationDialog("Import Timetable", isPresented: $showingImportOptions) {
            Button("Import JSON File") {
                importType = .json
                showingFileImporter = true
            }

            Button("Import CSV File") {
                importType = .csv
                showingFileImporter = true
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose file format to import")
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: importType == .json ? [.json] : [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .sheet(item: $selectedTimeSlot) { slot in
            quickAddCourseView(for: slot)
        }
        .sheet(isPresented: $showingShareSearch) {
            TimetableShareSearchView(timetableViewModel: viewModel)
        }
        .sheet(isPresented: $showingSharedTimetables) {
            SharedTimetablesView()
        }
        .sheet(isPresented: $showingShareRequests) {
            TimetableShareRequestsView()
        }
    }
}

extension TimetableView {

    // MARK: - Empty State
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Courses Yet")
                .font(.title2)
                .bold()

            Text("Add your courses manually or import from a file")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    viewModel.showingAddSheet = true
                } label: {
                    Label("Add Course", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 250)
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                Button {
                    showingImportOptions = true
                } label: {
                    Label("Import File", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: 250)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - TIMETABLE GRID
    var timetableGrid: some View {
        GeometryReader { geometry in
            let timeColumnWidth: CGFloat = 50
            let availableWidth = geometry.size.width - timeColumnWidth
            let columnWidth = availableWidth / 5
            let asyncCourses = viewModel.courses.filter { $0.isAsync }

            ScrollView {
                VStack(spacing: 0) {

                    // Days header
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

                    // Async row - only shown if there are async courses
                    if !asyncCourses.isEmpty {
                        HStack(spacing: 0) {
                            Text("Async")
                                .frame(width: timeColumnWidth)
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            ForEach(0..<5, id: \.self) { dayIndex in
                                ZStack {
                                    Rectangle()
                                        .stroke(Color.gray.opacity(0.2))
                                        .background(Color(white: 0.98))

                                    if dayIndex == 2 {  // Show in Wednesday column
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 4) {
                                                ForEach(asyncCourses) { course in
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(course.code)
                                                            .bold()
                                                            .font(.system(size: 10))
                                                            .lineLimit(1)
                                                        Text(course.name)
                                                            .font(.system(size: 8))
                                                            .lineLimit(1)
                                                    }
                                                    .padding(6)
                                                    .frame(width: columnWidth * 0.9)
                                                    .background(course.color.opacity(0.85))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(4)
                                                    .onTapGesture {
                                                        viewModel.selectCourseForEditing(course)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 4)
                                        }
                                    }
                                }
                                .frame(width: columnWidth, height: 60)
                            }
                        }
                    }

                    ForEach(hours, id: \.self) { hour in
                        HStack(spacing: 0) {
                            timeLabel(hour, width: timeColumnWidth)

                            ForEach(0..<5, id: \.self) { dayIndex in
                                ZStack {
                                    Rectangle()
                                        .stroke(Color.gray.opacity(0.2))
                                        .background(Color(white: 1.0))
                                        .onTapGesture {
                                            selectedTimeSlot = TimeSlot(day: dayIndex, hour: hour)
                                        }

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
        .frame(height: 600)  // Fixed height for the timetable grid
    }

    func timeLabel(_ hour: Int, width: CGFloat) -> some View {
        Text(formatHour(hour))
            .frame(width: width)
            .font(.caption2)
            .foregroundColor(.secondary)
    }

    // Format hour into AM/PM
    func formatHour(_ hour: Int) -> String {
        let display = hour == 12 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        return "\(display) \(suffix)"
    }

    // MARK: - CLASS BLOCKS PER SLOT
    func courseBlocks(day: Int, hour: Int, columnWidth: CGFloat) -> some View {
        let inThisHour = viewModel.getCourses(for: day, hour: hour)

        return ForEach(inThisHour) { course in
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
                .frame(maxWidth: .infinity, maxHeight: duration * 60)  // 60px per hour
                .background(course.color.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(4)
                .onTapGesture {
                    viewModel.selectCourseForEditing(course)
                }
            }
        }
    }
}

extension TimetableView {

    var courseList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enrolled Courses")
                .font(.headline)
                .padding(.horizontal)

            ForEach(viewModel.courses) { course in
                CourseDetailCard(course: course)
                    .padding(.horizontal)
            }
        }
    }

    func formatCourseTimes(_ times: [CourseTime]) -> String {
        let grouped = Dictionary(grouping: times, by: { $0.day })
        let sorted = grouped.sorted { $0.key < $1.key }

        return sorted.map { day, times in
            let dayName = days[day]
            let timeStrings = times.map { time in
                formatTime(time.startTime) + "-" + formatTime(time.endTime)
            }.joined(separator: ", ")
            return "\(dayName): \(timeStrings)"
        }.joined(separator: " • ")
    }

    func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        if minute == 0 {
            return "\(displayHour)\(suffix)"
        }
        return String(format: "%d:%02d%@", displayHour, minute, suffix)
    }
}

extension TimetableView {

    // MARK: - Import/Export Functions

    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                viewModel.errorMessage = "Permission denied to access file."
                viewModel.showingError = true
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            do {
                let data = try Data(contentsOf: url)

                if importType == .json {
                    viewModel.importFromJSON(data)
                } else {
                    viewModel.importFromCSV(data)
                }
            } catch {
                viewModel.errorMessage = "Failed to read file: \(error.localizedDescription)"
                viewModel.showingError = true
            }

        case .failure(let error):
            viewModel.errorMessage = "Failed to select file: \(error.localizedDescription)"
            viewModel.showingError = true
        }
    }

    func exportJSON() {
        guard let data = viewModel.exportToJSON() else { return }
        saveFile(data: data, filename: "timetable.json", contentType: .json)
    }

    func exportCSV() {
        let csvString = viewModel.exportToCSV()
        guard let data = csvString.data(using: String.Encoding.utf8) else { return }
        saveFile(data: data, filename: "timetable.csv", contentType: .commaSeparatedText)
    }

    func saveFile(data: Data, filename: String, contentType: UTType) {
        FileExportHelper.shareFile(data: data, filename: filename, contentType: contentType) {
            errorMessage in
            viewModel.errorMessage = errorMessage
            viewModel.showingError = true
        }
    }

    // MARK: - Quick Add from Time Slot

    func quickAddCourseView(for slot: TimeSlot) -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("Add Course")
                    .font(.title2)
                    .bold()

                Text("Selected: \(days[slot.day]) at \(formatHour(slot.hour))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    selectedTimeSlot = nil
                    viewModel.showingAddSheet = true
                } label: {
                    Label("Create New Course", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        selectedTimeSlot = nil
                    }
                }
            }
        }
    }
}

// MARK: - TimeSlot Identifiable
extension TimetableView.TimeSlot: Identifiable {
    var id: String {
        "\(day)-\(hour)"
    }
}

// MARK: - TimetableView Canvas Preview
struct TimetableView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TimetableView()
        }
        .environmentObject(GPAViewModel())
        .environmentObject(EventViewModel())
    }
}

struct CourseDetailCard: View {
    let course: TimetableCourse

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Header
            HStack {
                Circle()
                    .fill(course.color)
                    .frame(width: 12, height: 12)

                Text(course.code)
                    .font(.headline)

                Spacer()
            }

            Text(course.name)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Meta info
            if !course.instructor.isEmpty {
                Label(course.instructor, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !course.location.isEmpty {
                Label(course.location, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Time pills
            VStack(alignment: .leading, spacing: 6) {
                ForEach(course.times) { time in
                    HStack(spacing: 6) {
                        Text(dayName(time.day))
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(course.color.opacity(0.2))
                            .cornerRadius(6)

                        Text("\(format(time.startTime)) - \(format(time.endTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - Helpers (⭐ 이게 핵심)

    private func dayName(_ day: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days.indices.contains(day) ? days[day] : ""
    }

    private func format(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let suffix = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)

        if minute == 0 {
            return "\(displayHour)\(suffix)"
        }
        return String(format: "%d:%02d%@", displayHour, minute, suffix)
    }
}
