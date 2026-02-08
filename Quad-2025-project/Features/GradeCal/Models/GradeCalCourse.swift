//
//  GradeCalCourse.swift
//  Quad-2025-project
//

import Foundation
import FirebaseFirestore

struct GradeCalCourse: Identifiable, Codable, Equatable {
    @DocumentID var firestoreID: String?
    var id: UUID = UUID()
    var name: String
    var gradeItems: [GradeItem] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - Weight Properties
    
    /// Total weight assigned (graded + ungraded)
    var totalWeight: Double {
        gradeItems.reduce(0) { $0 + $1.weight }
    }
    
    /// Weight of graded items only
    var gradedWeight: Double {
        gradeItems.filter { $0.isGraded }.reduce(0) { $0 + $1.weight }
    }
    
    /// Weight of ungraded items
    var ungradedWeight: Double {
        gradeItems.filter { !$0.isGraded }.reduce(0) { $0 + $1.weight }
    }
    
    /// Check if weights exceed 100%
    var isWeightValid: Bool {
        totalWeight <= 100.0
    }
    
    /// Remaining weight available to assign
    var remainingWeight: Double {
        max(0, 100.0 - totalWeight)
    }
    
    /// Check if all 100% weight is assigned (required for AI predictions)
    var isFullyAssigned: Bool {
        abs(totalWeight - 100.0) < 0.01  // Allow small floating point error
    }
    
    /// Check if there are ungraded items (for AI to predict)
    var hasUngradedItems: Bool {
        gradeItems.contains { !$0.isGraded }
    }
    
    // MARK: - Grade Calculation
    
    /// Calculate current grade based on GRADED items only
    /// Redistributes weight proportionally among graded items
    var calculatedGrade: Double {
        let gradedItems = gradeItems.filter { $0.isGraded }
        let totalGradedWeight = gradedWeight
        
        guard totalGradedWeight > 0 else { return 0 }
        
        // Sum of (score% × weight) for graded items
        let weightedSum = gradedItems.reduce(0) { $0 + $1.weightedScore }
        
        // Normalize to 100 based on graded weight only
        return weightedSum / totalGradedWeight * 100
    }
    
    /// Letter grade based on calculated grade
    var letterGrade: String {
        let grade = calculatedGrade
        switch grade {
        case 93...100: return "A"
        case 90..<93: return "A-"
        case 87..<90: return "B+"
        case 83..<87: return "B"
        case 80..<83: return "B-"
        case 77..<80: return "C+"
        case 73..<77: return "C"
        case 70..<73: return "C-"
        case 67..<70: return "D+"
        case 63..<67: return "D"
        case 60..<63: return "D-"
        default: return "F"
        }
    }
    
    /// Items filtered by category
    func items(for category: GradeCategory) -> [GradeItem] {
        gradeItems.filter { $0.category == category }
    }
    
    /// Total weight for a specific category
    func totalWeight(for category: GradeCategory) -> Double {
        items(for: category).reduce(0) { $0 + $1.weight }
    }
    
    // MARK: - Mutations
    
    mutating func addItem(_ item: GradeItem) {
        gradeItems.append(item)
        updatedAt = Date()
    }
    
    mutating func updateItem(_ item: GradeItem) {
        if let index = gradeItems.firstIndex(where: { $0.id == item.id }) {
            gradeItems[index] = item
            updatedAt = Date()
        }
    }
    
    mutating func deleteItem(_ item: GradeItem) {
        gradeItems.removeAll { $0.id == item.id }
        updatedAt = Date()
    }
}
