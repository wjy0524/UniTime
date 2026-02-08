//
//  GradeCalAIButton.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 2/2/26.
//  Floating button for GradeCal AI (course-specific)
//

import SwiftUI

struct GradeCalAIButton: View {
    let course: GradeCalCourse
    @State private var showChat = false
    
    var body: some View {
        Button {
            showChat = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Predict")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color("UTAustinOrange"), Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .sheet(isPresented: $showChat) {
            GradeCalAIChatView(course: course)
        }
    }
}
