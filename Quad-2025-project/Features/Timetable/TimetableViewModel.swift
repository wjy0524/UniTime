//  TimetableViewModel.swift
//  Quad-2025-project
//


import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore


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

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() {
        observeAuthState()
    }

    deinit {
        listener?.remove()
    }
    
    private func observeAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }

            if user != nil {
                self.loadCoursesFromFirebase()
            } else {
                self.courses = []
                self.listener?.remove()
            }
        }
    }


    // MARK: - 🔥 Load from Firebase

    func loadCoursesFromFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = db.collection("users")
            .document(uid)
            .collection("timetable")
            .document("myCourses")
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    self?.errorMessage = "Failed to load timetable: \(error.localizedDescription)"
                    self?.showingError = true
                    return
                }

                guard let data = snapshot?.data(),
                      let coursesData = data["courses"] as? [[String: Any]] else {
                    self?.courses = []
                    return
                }

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: coursesData)
                    let decoded = try JSONDecoder().decode([TimetableCourse].self, from: jsonData)
                    DispatchQueue.main.async {
                        self?.courses = decoded
                        for course in decoded {
                                self?.joinCourseChat(course.code)
                        }
                    }
                } catch {
                    self?.errorMessage = "Failed to decode timetable."
                    self?.showingError = true
                }
            }
    }

    // MARK: - 🔥 Save to Firebase

    private func saveCoursesToFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let encoded = try JSONEncoder().encode(courses)
            let jsonObject = try JSONSerialization.jsonObject(with: encoded)

            db.collection("users")
                .document(uid)
                .collection("timetable")
                .document("myCourses")
                .setData(["courses": jsonObject], merge: true)

        } catch {
            errorMessage = "Failed to save timetable."
            showingError = true
        }
    }

    // MARK: - CRUD

    func addCourse(_ course: TimetableCourse) {
        courses.append(course)
        saveCoursesToFirebase()
        joinCourseChat(course.code)
    }

    func updateCourse(_ course: TimetableCourse) {
        if let index = courses.firstIndex(where: { $0.id == course.id }) {
            courses[index] = course
            saveCoursesToFirebase()
        }
    }

    func deleteCourse(_ course: TimetableCourse) {
        courses.removeAll { $0.id == course.id }
        saveCoursesToFirebase()
    }

    func clearAll() {
        courses = []
        saveCoursesToFirebase()
    }

    // MARK: - Import

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
                    id: UUID(),
                    name: importedCourse.courseName,
                    code: "\(importedCourse.department) \(importedCourse.number)",
                    instructor: "",
                    location: location.trimmingCharacters(in: .whitespaces),
                    colorHex: "#BF5700",
                    times: times
                )

                newCourses.append(course)
            }

            courses.append(contentsOf: newCourses)
            saveCoursesToFirebase()

        } catch {
            errorMessage = "Failed to import JSON."
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
            errorMessage = "No valid courses found in CSV"
            showingError = true
        } else {
            courses.append(contentsOf: importedCourses)
            saveCoursesToFirebase()
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
            !course.isAsync &&
            course.times.contains { time in
                time.day == day && hour == time.startTime / 60
            }
        }
    }

    func selectCourseForEditing(_ course: TimetableCourse) {
        selectedCourse = course
        showingEditSheet = true
    }
    
    private func joinCourseChat(_ code: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ UID NIL")
            return
        }

        print("🔥 joinCourseChat CALLED for:", code)

        let safeCode = code.replacingOccurrences(of: " ", with: "_")
            .uppercased()

        print("🔥 safeCode:", safeCode)

        let chatRef = db.collection("courseChats").document(safeCode)

        chatRef.setData([
            "courseCode": code,
            "members": FieldValue.arrayUnion([uid]),
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("❌ Firestore error:", error)
            } else {
                print("✅ courseChat write success")
            }
        }
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


