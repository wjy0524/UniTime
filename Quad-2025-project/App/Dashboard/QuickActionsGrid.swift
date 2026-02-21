//
//  QuickActionsGrid.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/20/26.
//

import SwiftUI

struct QuickActionsGrid: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            LazyVGrid(columns: columns, spacing: 20) {
                
                // 1행
                actionItem(title: "Board", icon: "bubble.left.and.bubble.right.fill", color: .blue, destination: BoardView())
                actionItem(title: "GPA", icon: "chart.bar.fill", color: .orange, destination: GPAFullView())
                actionItem(title: "Dining", icon: "fork.knife.circle.fill", color: .green, destination: DiningHomeView())
                actionItem(title: "Calendar", icon: "calendar.circle.fill", color: .red, destination: CalendarView())
                
                // 2행
                actionItem(title: "Study", icon: "book.circle.fill", color: .indigo, destination: StudyTrackerView())
                actionItem(title: "Market", icon: "cart.circle.fill", color: .purple, destination: MarketplaceView())
                actionItem(title: "Timetable", icon: "clock.circle.fill", color: .teal, destination: TimetableView())
                actionItem(title: "GradeCal", icon: "a.circle.fill", color: Color("UTAustinOrange"), destination: GradeCalView())
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(20)
        }
    }
    
    // 제네릭을 사용하여 어떤 뷰로든 이동 가능하게 수정
    private func actionItem<Destination: View>(title: String, icon: String, color: Color, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}
