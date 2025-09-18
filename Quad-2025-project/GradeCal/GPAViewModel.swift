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
    
    private let gradePoints: [String: Double] = [
        "A": 4.0, "A-": 3.7,
        "B+": 3.3, "B": 3.0, "B-": 2.7,
        "C+": 2.3, "C": 2.0, "C-": 1.7,
        "D+": 1.3, "D": 1.0, "F": 0.0
    ]
    
    // MARK: - Firebase Helpers
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // 🔹 Firestore에서 과목 불러오기
    func fetchCourses() {
        guard let uid = userId else { return }
        db.collection("users").document(uid).collection("courses")
            .order(by: "semesterOrder") // 학기 순서대로 정렬 (추가 필드 필요)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching courses: \(error.localizedDescription)")
                    return
                }
                if let docs = snapshot?.documents {
                    self.courses = docs.compactMap { doc in
                        try? doc.data(as: Course.self)
                    }
                }
            }
    }
    
    // 🔹 Firestore에 과목 추가
    func addCourse(_ course: Course) {
        guard let uid = userId else { return }
        let courseId = course.id ?? UUID().uuidString   // ✅ nil이면 새 ID 생성
        
        do {
            try db.collection("users").document(uid)
                .collection("courses")
                .document(courseId)
                .setData(from: course)
            
            var newCourse = course
            newCourse.id = courseId   // ✅ Firestore에 저장된 ID 반영
            courses.append(newCourse)
            
        } catch {
            print("❌ Error adding course: \(error.localizedDescription)")
        }
    }

    // 🔹 Firestore에서 과목 수정
    func updateCourse(_ updated: Course) {
        guard let uid = userId else { return }
        guard let courseId = updated.id else { return }   // ✅ id 없으면 수정 불가
        
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

    // 🔹 Firestore에서 과목 삭제
    func deleteCourse(_ course: Course) {
        guard let uid = userId else { return }
        guard let courseId = course.id else { return }   // ✅ id 없으면 삭제 불가
        
        db.collection("users").document(uid)
            .collection("courses")
            .document(courseId)
            .delete { error in
                if let error = error {
                    print("❌ Error deleting course: \(error.localizedDescription)")
                } else {
                    self.courses.removeAll { $0.id == course.id }
                }
            }
    }
    
    // MARK: - GPA 계산
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
        
        let overallGPA = totalCredits > 0 ? totalPoints / Double(totalCredits) : 0.0
        let majorGPA = majorCredits > 0 ? majorPoints / Double(majorCredits) : 0.0
        
        return GPASummary(overallGPA: overallGPA, majorGPA: majorGPA, totalCredits: totalCredits)
    }
    
    func gpaHistory() -> [GPAEntry] {
        var history: [GPAEntry] = []
        for sem in Semester.allCases {
            if let summary = gpaForSemester(sem) {
                history.append(GPAEntry(semester: sem.rawValue, gpa: summary.overallGPA))
            }
        }
        return history
    }
    
    func coursesForSemester(_ semester: Semester) -> [Course] {
        courses.filter { $0.semester == semester }
    }
    
    // GPA 타입 정의

}

