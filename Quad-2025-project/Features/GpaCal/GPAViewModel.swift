
//
//  GPAViewModel.swift
//  Quad-2025-project
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct GPASummary {
    let overallGPA: Double
    let majorGPA: Double
    let totalCredits: Int
}

struct GPAEntry: Identifiable {
    let id = UUID()
    let semester: String
    let gpa: Double
}

class GPAViewModel: ObservableObject {
    @Published var courses: [Course] = []
    private let db = Firestore.firestore()
    
    let gradePoints: [String: Double] = [
        "A": 4.0, "A-": 3.7,
        "B+": 3.3, "B": 3.0, "B-": 2.7,
        "C+": 2.3, "C": 2.0, "C-": 1.7,
        "D+": 1.3, "D": 1.0, "F": 0.0
    ]
    
    // MARK: - Firebase
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Load Courses from Firebase
    func fetchCourses() {
        guard let uid = userId else { return }
        
        db.collection("users").document(uid).collection("courses")
            .order(by: "semesterOrder")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching courses: \(error.localizedDescription)")
                    return
                }
                self.courses = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Course.self)
                } ?? []
            }
    }
    
    // MARK: - Add Course
    func addCourse(_ course: Course) {
        guard let uid = userId else { return }
        let courseId = course.id ?? UUID().uuidString
        
        do {
            try db.collection("users").document(uid)
                .collection("courses")
                .document(courseId)
                .setData(from: course)
            
            var newCourse = course
            newCourse.id = courseId
            courses.append(newCourse)
            
        } catch {
            print("❌ Error adding course: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update Course
    func updateCourse(_ updated: Course) {
        guard let uid = userId else { return }
        guard let courseId = updated.id else { return }
        
        do {
            try db.collection("users").document(uid)
                .collection("courses")
                .document(courseId)
                .setData(from: updated)
            
            if let index = courses.firstIndex(where: { $0.id == updated.id }) {
                courses[index] = updated
            }
            
        } catch {
            print("❌ Error updating course: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Course
    func deleteCourse(_ course: Course) {
        guard let uid = userId else { return }
        guard let courseId = course.id else { return }
        
        db.collection("users").document(uid)
            .collection("courses")
            .document(courseId)
            .delete { error in
                if let error = error {
                    print("❌ Error deleting: \(error.localizedDescription)")
                } else {
                    self.courses.removeAll { $0.id == course.id }
                }
            }
    }
    
    // MARK: - Semester GPA
    func gpaForSemester(_ semester: Semester) -> GPASummary? {
        let semesterCourses = courses.filter { $0.semester == semester }
        guard !semesterCourses.isEmpty else { return nil }
        
        var totalPoints = 0.0
        var totalCredits = 0
        var majorPoints = 0.0
        var majorCredits = 0
        
        for course in semesterCourses {
            if let gp = gradePoints[course.grade] {
                totalPoints += gp * Double(course.credits)
                totalCredits += course.credits
                
                if course.isMajor {
                    majorPoints += gp * Double(course.credits)
                    majorCredits += course.credits
                }
            }
        }
        
        return GPASummary(
            overallGPA: totalCredits > 0 ? totalPoints / Double(totalCredits) : 0.0,
            majorGPA: majorCredits > 0 ? majorPoints / Double(majorCredits) : 0.0,
            totalCredits: totalCredits
        )
    }
    
    // MARK: - Overall GPA for Dashboard
    var overallGPA: Double {
        let total = courses.reduce((points: 0.0, credits: 0)) { acc, course in
            guard let gp = gradePoints[course.grade] else { return acc }
            return (
                acc.points + gp * Double(course.credits),
                acc.credits + course.credits
            )
        }
        return total.credits > 0 ? total.points / Double(total.credits) : 0.0
    }
    
    var majorGPA: Double {
        let majorCourses = courses.filter { $0.isMajor }
        
        let total = majorCourses.reduce((points: 0.0, credits: 0)) { acc, course in
            guard let gp = gradePoints[course.grade] else { return acc }
            return (
                acc.points + gp * Double(course.credits),
                acc.credits + course.credits
            )
        }
        return total.credits > 0 ? total.points / Double(total.credits) : 0.0
    }
    
    var totalCompletedCredits: Int {
        courses.reduce(0) { $0 + $1.credits }
    }
    
    // MARK: - History Chart Data
    func gpaHistory() -> [GPAEntry] {
        Semester.allCases.compactMap { sem in
            if let summary = gpaForSemester(sem) {
                return GPAEntry(semester: sem.rawValue, gpa: summary.overallGPA)
            }
            return nil
        }
    }
    
    func coursesForSemester(_ semester: Semester) -> [Course] {
        courses
            .filter { $0.semester == semester }
            .sorted { $0.semesterOrder < $1.semesterOrder }
    }
}


