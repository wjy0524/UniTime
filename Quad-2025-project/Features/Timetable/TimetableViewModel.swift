//
//  TimetableViewModel.swift
//  Quad-2025-project
//
//  Created on Timetable Feature Enhancement
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

class TimetableViewModel: ObservableObject {
    @Published var courses: [TimetableCourse] = []
    @Published var showingAddSheet = false
    @Published var showingEditSheet = false
    @Published var selectedCourse: TimetableCourse?
    @Published var showingImportPicker = false
    @Published var errorMessage: String?
    @Published var showingError = false

    private let userDefaultsKey = "savedCourses"

    init() {
        loadCourses()
    }

    // MARK: - Persistence

    func saveCourses() {
        if let encoded = try? JSONEncoder().encode(courses) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func loadCourses() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
            let decoded = try? JSONDecoder().decode([TimetableCourse].self, from: data)
        {
            courses = decoded
        } else {
            courses = []
        }
    }

    // MARK: - CRUD Operations

    func addCourse(_ course: TimetableCourse) {
        courses.append(course)
        saveCourses()
    }

    func updateCourse(_ course: TimetableCourse) {
        if let index = courses.firstIndex(where: { $0.id == course.id }) {
            courses[index] = course
            saveCourses()
        }
    }

    func deleteCourse(_ course: TimetableCourse) {
        courses.removeAll { $0.id == course.id }
        saveCourses()
    }

    func deleteCourse(at offsets: IndexSet) {
        courses.remove(atOffsets: offsets)
        saveCourses()
    }

    // MARK: - Import Functions

    func importFromJSON(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let importedCourses = try decoder.decode([TimetableCourse].self, from: data)
            courses.append(contentsOf: importedCourses)
            saveCourses()
        } catch {
            errorMessage = "Failed to import JSON: \(error.localizedDescription)"
            showingError = true
        }
    }

    func importFromCSV(_ data: Data) {
        guard let csvString = String(data: data, encoding: .utf8) else {
            errorMessage = "Failed to read CSV file"
            showingError = true
            return
        }

        let importedCourses = CSVCourseImporter.parseCourses(from: csvString)
        if importedCourses.isEmpty {
            errorMessage = "No valid courses found in CSV file"
            showingError = true
        } else {
            courses.append(contentsOf: importedCourses)
            saveCourses()
        }
    }

    // MARK: - Export Functions

    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(courses)
    }

    func exportToCSV() -> String {
        var csv = "name,code,instructor,location,colorHex,day,startTime,endTime\n"

        for course in courses {
            for time in course.times {
                let line =
                    "\(course.name),\(course.code),\(course.instructor),\(course.location),\(course.colorHex),\(time.day),\(time.startTime),\(time.endTime)\n"
                csv += line
            }
        }

        return csv
    }

    // MARK: - Helper Functions

    func getCourses(for day: Int, hour: Int) -> [TimetableCourse] {
        return courses.filter { course in
            course.times.contains { time in
                time.day == day && hour == time.startTime / 60
            }
        }
    }

    func selectCourseForEditing(_ course: TimetableCourse) {
        selectedCourse = course
        showingEditSheet = true
    }

    func clearAll() {
        courses = []
        saveCourses()
    }
}
