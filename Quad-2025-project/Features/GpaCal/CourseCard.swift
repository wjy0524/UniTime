//
//  CourseCard.swift
//  Quad-2025-project
//

import SwiftUI

struct CourseCard: View {
    let course: Course

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(course.credits) credits")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(course.grade)
                .font(.title3)
                .bold()
                .foregroundColor(gradeColor(course.grade))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 4)
    }

    private func gradeColor(_ grade: String) -> Color {
        if grade.hasPrefix("A") { return .green }
        if grade.hasPrefix("B") { return .blue }
        if grade.hasPrefix("C") { return .orange }
        if grade.hasPrefix("D") { return .red }
        return .gray
    }
}
