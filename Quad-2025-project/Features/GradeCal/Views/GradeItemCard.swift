//
//  GradeItemCard.swift
//  Quad-2025-project
//
//  Reusable card component for displaying a grade item
//

import SwiftUI

struct GradeItemCard: View {
    let item: GradeItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Score indicator
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                if item.isGraded {
                    Text(String(format: "%.0f", item.percentageScore))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(scoreColor)
                } else {
                    Text("?")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let score = item.scoreReceived {
                        Text("\(Int(score))/\(Int(item.scoreTotal))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Not graded")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%% weight", item.weight))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Contribution
            VStack(alignment: .trailing, spacing: 2) {
                if item.isGraded {
                    Text(String(format: "+%.1f", item.weightedScore))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("pts")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("TBD")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    private var scoreColor: Color {
        guard item.isGraded else { return .gray }
        let score = item.percentageScore
        switch score {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }
}

#Preview {
    GradeItemCard(item: GradeItem(
        name: "Midterm Exam",
        scoreReceived: 85,
        scoreTotal: 100,
        weight: 30,
        category: .exams
    ))
    .padding()
}
