//
//  ScenarioGenerator.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 2/2/26.
//  Math engine for generating grade prediction scenarios
//

import Foundation

struct GradeScenario: Identifiable {
    let id = UUID()
    let predictions: [ItemPrediction]  // What scores needed on remaining items
    let finalGrade: Double
    let letterGrade: String
    let explanation: String
}

struct ItemPrediction {
    let itemName: String
    let category: GradeCategory
    let weight: Double
    let predictedScore: Double
}

struct GradeCoverage {
    let completedWeight: Double
    let remainingWeight: Double
    let coveragePercent: Double
    
    var status: CoverageStatus {
        switch coveragePercent {
        case ..<20: return .insufficient
        case 20..<40: return .uncertain
        default: return .sufficient
        }
    }
    
    enum CoverageStatus {
        case insufficient  // < 20% - don't generate
        case uncertain     // 20-40% - warn user
        case sufficient    // >= 40% - normal generation
    }
}

class ScenarioGenerator {
    
    let course: GradeCalCourse
    
    init(course: GradeCalCourse) {
        self.course = course
    }
    
    // MARK: - Coverage Check
    
    func calculateCoverage() -> GradeCoverage {
        let completedWeight = course.gradeItems.reduce(0) { $0 + $1.weight }
        let remainingWeight = 100.0 - completedWeight
        let coveragePercent = completedWeight
        
        return GradeCoverage(
            completedWeight: completedWeight,
            remainingWeight: remainingWeight,
            coveragePercent: coveragePercent
        )
    }
    
    // MARK: - Current Grade
    
    func currentWeightedScore() -> Double {
        // Sum of (score% × weight) for completed items
        return course.gradeItems.reduce(0) { $0 + $1.weightedScore }
    }
    
    // MARK: - Target Feasibility
    
    func isTargetPossible(_ targetGrade: Double) -> (possible: Bool, maxAchievable: Double) {
        let currentScore = currentWeightedScore()
        let remainingWeight = 100.0 - course.totalWeight
        
        // Best case: 100% on all remaining
        let maxPossible = currentScore + remainingWeight
        
        // Worst case: 0% on all remaining
        let minPossible = currentScore
        
        let possible = targetGrade >= minPossible && targetGrade <= maxPossible
        
        return (possible, maxPossible)
    }
    
    // MARK: - Scenario Generation
    
    /// Generate scenarios to reach target grade
    /// Returns nil if coverage is insufficient
    func generateScenarios(targetGrade: Double, count: Int = 10) -> [GradeScenario]? {
        let coverage = calculateCoverage()
        
        // Don't generate if < 20% coverage
        guard coverage.status != .insufficient else {
            return nil
        }
        
        let (possible, maxAchievable) = isTargetPossible(targetGrade)
        
        if !possible {
            // Return one scenario explaining why it's impossible
            return [createImpossibleScenario(target: targetGrade, max: maxAchievable)]
        }
        
        // Generate varied realistic scenarios
        return (0..<count).map { index in
            generateSingleScenario(targetGrade: targetGrade, variation: index)
        }
    }
    
    private func generateSingleScenario(targetGrade: Double, variation: Int) -> GradeScenario {
        let currentScore = currentWeightedScore()
        let remainingWeight = 100.0 - course.totalWeight
        let neededScore = targetGrade - currentScore
        
        // Base average needed on remaining items
        let baseAverage = (neededScore / remainingWeight) * 100
        
        // Create variations by adjusting distribution
        // variation 0 = even distribution
        // higher variations = more uneven (stronger in some areas)
        
        var predictions: [ItemPrediction] = []
        
        // For now, simple even distribution
        // TODO: Add more sophisticated variation logic
        let adjustedAverage = min(100, max(0, baseAverage + Double(variation - 5) * 2))
        
        // Create predictions for "remaining" items
        // Since we don't track "remaining" items explicitly,
        // we'll create placeholder predictions based on remaining weight
        let prediction = ItemPrediction(
            itemName: "Remaining Work",
            category: .other,
            weight: remainingWeight,
            predictedScore: adjustedAverage
        )
        predictions.append(prediction)
        
        let finalGrade = currentScore + (adjustedAverage / 100 * remainingWeight)
        
        return GradeScenario(
            predictions: predictions,
            finalGrade: finalGrade,
            letterGrade: letterGrade(for: finalGrade),
            explanation: "Score ~\(Int(adjustedAverage))% on remaining \(String(format: "%.1f", remainingWeight))% of coursework to achieve \(String(format: "%.1f", finalGrade))%"
        )
    }
    
    private func createImpossibleScenario(target: Double, max: Double) -> GradeScenario {
        return GradeScenario(
            predictions: [],
            finalGrade: max,
            letterGrade: letterGrade(for: max),
            explanation: "A grade of \(String(format: "%.1f", target))% is not achievable. Even with 100% on all remaining work, the maximum possible is \(String(format: "%.1f", max))%."
        )
    }
    
    private func letterGrade(for grade: Double) -> String {
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
}
