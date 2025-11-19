//
//  WhiteSummaryCard.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct WhiteSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let valueColor: Color

    var body: some View {
        VStack(spacing: 6) {
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(valueColor)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }
}
