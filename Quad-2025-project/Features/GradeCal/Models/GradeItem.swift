//
//  GradeItem.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 1/27/26.
//

import Foundation

/// Represents the category of a grade item
enum GradeCategory: String, Codable, CaseIterable, Identifiable {
    case assignments = "Assignments"
    case quizzes = "Quizzes"
    case exams = "Exams"
    case other = "Other"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .assignments: return "doc.text.fill"
        case .quizzes: return "questionmark.circle.fill"
        case .exams: return "pencil.and.paper"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// Individual grade item (e.g., "Exam 1", "Quiz 3")
struct GradeItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var scoreReceived: Double?       // Points earned (e.g., 85)
    var scoreTotal: Double         // Total possible points (e.g., 100)
    var weight: Double             // Weight as percentage (e.g., 20 for 20%)
    var category: GradeCategory
    var createdAt: Date = Date()
    
    /// Is this item graded yet?
    var isGraded: Bool {
        scoreReceived != nil
    }
    

    /// Calculated percentage score (0-100)
    var percentageScore: Double {
        guard let score = scoreReceived, scoreTotal > 0 else { return 0 }
        return (score / scoreTotal) * 100
    }
    
    /// Weighted contribution to final grade
       var weightedScore: Double {
           guard isGraded else { return 0 }
           return percentageScore * (weight / 100)
       }
}
