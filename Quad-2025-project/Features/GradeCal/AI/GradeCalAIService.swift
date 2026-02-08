//
//  GradeCalAIService.swift
//  Quad-2025-project
//

import FirebaseFunctions
import Foundation

class GradeCalAIService {
    private let functions = Functions.functions()
    
    func getPrediction(
        courseData: GradeCalCourse,
        userQuestion: String
    ) async throws -> String {
        
        let context = buildCourseContext(course: courseData)
        
        let result = try await functions.httpsCallable("gradeCalPredict").call([
            "courseContext": context,
            "userQuestion": userQuestion
        ])
        
        if let data = result.data as? [String: Any],
           let reply = data["reply"] as? String {
            return reply
        }
        
        throw NSError(domain: "GradeCalAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
    }
    
    private func buildCourseContext(course: GradeCalCourse) -> [String: Any] {
        // Get only GRADED items
        let gradedItems = course.gradeItems.filter { $0.isGraded }
        
        // Calculate current weighted points from graded items ONLY
        var currentWeightedPoints: Double = 0
        var gradedWeight: Double = 0
        
        let completedItems = gradedItems.map { item -> [String: Any] in
            let points = item.percentageScore * item.weight / 100
            currentWeightedPoints += points
            gradedWeight += item.weight
            
            return [
                "name": item.name,
                "category": item.category.rawValue,
                "score": item.percentageScore,
                "weight": item.weight,
                "points": points  // 🔥 Add actual points contributed
            ]
        }
        
        // Get UNGRADED items
        let ungradedItems = course.gradeItems.filter { !$0.isGraded }.map { item in
            return [
                "name": item.name,
                "category": item.category.rawValue,
                "weight": item.weight
            ]
        }
        
        let ungradedWeight = ungradedItems.reduce(0.0) { $0 + ($1["weight"] as? Double ?? 0) }
        
        // Current grade based on graded items only (normalized)
        let currentGradeNormalized = gradedWeight > 0 ? (currentWeightedPoints / gradedWeight) * 100 : 0
        
        return [
            "courseName": course.name,
            "completedItems": completedItems,
            "ungradedItems": ungradedItems,
            "currentGrade": currentGradeNormalized,
            "letterGrade": course.letterGrade,
            "totalWeightCompleted": gradedWeight,
            "remainingWeight": ungradedWeight,
            "currentWeightedPoints": currentWeightedPoints  // 🔥 Send actual points!
        ]
    }
}
