//  TimetableViewModel.swift
//  Quad-2025-project
//

import Foundation
import SwiftUI

// MARK: - UT Timetable Import Models (Adapter용)

struct ImportedTimetable: Decodable {
    let name: String
    let courses: [ImportedCourse]
}

struct ImportedCourse: Decodable {
    let courseName: String
    let department: String
    let number: String
    let schedule: ImportedSchedule
}

struct ImportedSchedule: Decodable {
    let meetings: [ImportedMeeting]
}

struct ImportedMeeting: Decodable {
    let days: [String]  // ["Monday", "Wednesday"]
    let startTime: Int  // minutes (e.g. 540 = 9:00 AM)
    let endTime: Int
    let location: ImportedLocation
}

struct ImportedLocation: Decodable {
    let building: String
    let room: String
}

// MARK: - ViewModel

class TimetableViewModel: ObservableObject {

    @Published var courses: [TimetableCourse] = []
    @Published var showingAddSheet = false
    @Published var showingEditSheet = false
    @Published var selectedCourse: TimetableCourse?
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

    // MARK: - CRUD

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

    func clearAll() {
        courses = []
        saveCourses()
    }

    // MARK: - JSON Import (Adapter)

    func importFromJSON(_ data: Data) {
        do {
            let imported = try JSONDecoder().decode(ImportedTimetable.self, from: data)
            var newCourses: [TimetableCourse] = []

            for importedCourse in imported.courses {

                var times: [CourseTime] = []

                for meeting in importedCourse.schedule.meetings {
                    for day in meeting.days {
                        if let dayIndex = dayStringToIndex(day) {
                            times.append(
                                CourseTime(
                                    day: dayIndex,
                                    startTime: meeting.startTime,
                                    endTime: meeting.endTime
                                )
                            )
                        }
                    }
                }

                let location =
                    "\(importedCourse.schedule.meetings.first?.location.building ?? "") "
                    + "\(importedCourse.schedule.meetings.first?.location.room ?? "")"

                let course = TimetableCourse(
                    id: UUID(),  // ✅ UUID FIX
                    name: importedCourse.courseName,
                    code: "\(importedCourse.department) \(importedCourse.number)",
                    instructor: "",
                    location: location.trimmingCharacters(in: .whitespaces),
                    colorHex: "#BF5700",  // UT Austin Orange,
                    times: times
                )

                newCourses.append(course)
            }

            courses.append(contentsOf: newCourses)
            saveCourses()

        } catch {
            errorMessage = "Failed to import JSON: The data isn't in the correct format."
            showingError = true
        }
    }

    // MARK: - CSV Import

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

    // MARK: - Export

    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(courses)
    }

    func exportToCSV() -> String {
        var csv = "name,code,instructor,location,colorHex,day,startTime,endTime\n"

        for course in courses {
            for time in course.times {
                csv +=
                    "\(course.name),\(course.code),\(course.instructor),\(course.location),\(course.colorHex),\(time.day),\(time.startTime),\(time.endTime)\n"
            }
        }
        return csv
    }

    // MARK: - Helpers

    func getCourses(for day: Int, hour: Int) -> [TimetableCourse] {
        courses.filter { course in
            !course.isAsync
                && course.times.contains { time in
                    time.day == day && hour == time.startTime / 60
                }
        }
    }

    func selectCourseForEditing(_ course: TimetableCourse) {
        selectedCourse = course
        showingEditSheet = true
    }
}

// MARK: - Day String → Index

func dayStringToIndex(_ day: String) -> Int? {
    switch day.lowercased() {
    case "monday": return 0
    case "tuesday": return 1
    case "wednesday": return 2
    case "thursday": return 3
    case "friday": return 4
    default: return nil
    }
}
