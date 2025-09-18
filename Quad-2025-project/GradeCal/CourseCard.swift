//
//  CourseCard.swift
//  Quad-2025-project
//

import SwiftUI

struct CourseCard: View {
    let course: Course

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(course.name)
                        .font(.body)
                        .bold()
                    if course.isMajor {
                        Text("Major")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color("UTAustinOrange").opacity(0.2))
                            .foregroundColor(Color("UTAustinOrange"))
                            .cornerRadius(6)
                    }
                }
                Text("\(course.credits) credits")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(course.grade)
                .font(.headline)
                .bold()
                .foregroundColor(gradeColor(course.grade))
        }
        .padding(.vertical, 10) // ✅ 세로 padding만
        .contentShape(Rectangle()) // ✅ 스와이프 영역 활성화
    }

    private func gradeColor(_ grade: String) -> Color {
        if grade.hasPrefix("A") { return .green }
        if grade.hasPrefix("B") { return .blue }
        if grade.hasPrefix("C") { return .orange }
        if grade.hasPrefix("D") { return .red }
        return .gray
    }
}



