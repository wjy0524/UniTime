//
//  ShadcnChartContainer.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

//
//  ShadcnChartContainer.swift
//  Quad-2025-project
//
//  Created by ChatGPT on 2025-11-18.
//

import SwiftUI
import Charts

// MARK: - Theme (Shadcn의 색상 시스템 대응)
struct ShadcnChartTheme {
    var colors: [String: Color]
    
    func color(_ key: String) -> Color {
        colors[key] ?? Color.blue
    }
}

// MARK: - Tooltip (Shadcn UI 스타일)
struct ShadcnChartTooltip: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(value))")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4)
        )
    }
}

// MARK: - Legend (Shadcn 스타일)
struct ShadcnChartLegend: View {
    var items: [(String, Color)]
    
    var body: some View {
        HStack(spacing: 14) {
            ForEach(items, id: \.0) { (name, color) in
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - ChartContainer (Shadcn의 ResponsiveContainer 대응)
struct ShadcnChartContainer<Content: View>: View {
    let theme: ShadcnChartTheme
    @ViewBuilder let content: () -> Content
    
    init(
        theme: ShadcnChartTheme,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.theme = theme
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 12) {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

