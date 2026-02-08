//
//  SemesterSummaryLargeGradientCard.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//


import SwiftUI

struct SemesterSummaryLargeGradientCard: View {
    let title: String
    let overallGPA: Double
    let majorGPA: Double
    let credits: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)

            HStack {
                summaryItem("Semester GPA", overallGPA)
                summaryItem("Major GPA", majorGPA)
                summaryItem("Credits", Double(credits))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color("UTAustinOrange"),
                    Color(red: 0.78, green: 0.32, blue: 0.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .shadow(color: Color("UTAustinOrange").opacity(0.25),
                radius: 10, x: 0, y: 4)
    }

    private func summaryItem(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))

            Text(value == floor(value) ?
                 String(format: "%.0f", value) :
                 String(format: "%.2f", value))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            if title.contains("GPA") {
                Text("/ 4.0")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
