//
//  GradeCalAIViewModel.swift
//  Quad-2025-project
//

import SwiftUI

@MainActor
class GradeCalAIViewModel: ObservableObject {
    
    @Published var messages: [AIChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var coverageWarning: String?
    
    private let aiService = GradeCalAIService()
    private let course: GradeCalCourse
    
    init(course: GradeCalCourse) {
        self.course = course
        checkRequirements()
    }
    
    // MARK: - Requirements Check
    
    private func checkRequirements() {
        if !course.isFullyAssigned {
            // Not all 100% weight assigned
            coverageWarning = "Please assign all 100% of the course weight before generating predictions. Currently: \(String(format: "%.0f", course.totalWeight))%"
        } else if !course.hasUngradedItems {
            // All items are graded - nothing to predict
            coverageWarning = "All items are graded. Add ungraded items (like upcoming exams) for the AI to predict what you need."
        } else if course.gradedWeight < 20 {
            // Not enough graded items
            coverageWarning = "Only \(String(format: "%.0f", course.gradedWeight))% is graded. Predictions may be less accurate."
        } else {
            coverageWarning = nil
        }
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ text: String) async {
        // Block if not fully assigned
        if !course.isFullyAssigned {
            let warningMessage = AIChatMessage(
                text: "Please assign all 100% of the course weight first. Currently only \(String(format: "%.0f", course.totalWeight))% is assigned.\n\nAdd more items (graded or ungraded) until the total weight equals 100%.",
                isFromUser: false
            )
            messages.append(AIChatMessage(text: text, isFromUser: true))
            messages.append(warningMessage)
            return
        }
        
        // Block if no ungraded items
        if !course.hasUngradedItems {
            let warningMessage = AIChatMessage(
                text: "All your items are already graded, so there's nothing to predict!\n\nYour final grade is: \(course.letterGrade) (\(String(format: "%.1f", course.calculatedGrade))%)\n\nTo use predictions, add upcoming assignments or exams without a score.",
                isFromUser: false
            )
            messages.append(AIChatMessage(text: text, isFromUser: true))
            messages.append(warningMessage)
            return
        }
        
        // Add user message
        let userMessage = AIChatMessage(text: text, isFromUser: true)
        messages.append(userMessage)
        
        isLoading = true
        errorMessage = nil
        
        do {
            let reply = try await aiService.getPrediction(
                courseData: course,
                userQuestion: text
            )
            
            let aiMessage = AIChatMessage(text: reply, isFromUser: false)
            messages.append(aiMessage)
        } catch {
            errorMessage = "Failed to get prediction"
            let errorMsg = AIChatMessage(
                text: "Sorry, I couldn't generate a prediction. Please try again.",
                isFromUser: false
            )
            messages.append(errorMsg)
        }
        
        isLoading = false
    }
    
    // MARK: - Quick Actions
    
    func askForA() async {
        await sendMessage("What do I need to get an A in this course?")
    }
    
    func askForTarget(_ grade: Double) async {
        let letterGrade: String
            switch grade {
            case 93: letterGrade = "A"
            case 90: letterGrade = "A-"
            case 87: letterGrade = "B+"
            case 84: letterGrade = "B"
            case 80: letterGrade = "B-"
            case 77: letterGrade = "C+"
            default: letterGrade = "\(Int(grade))%"
            }
            
            await sendMessage("What do I need to get an \(letterGrade) (\(Int(grade))% or above)?")
    }
}
