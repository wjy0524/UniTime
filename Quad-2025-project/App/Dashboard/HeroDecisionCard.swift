//
//  HeroDecisionCard.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/20/26.
//

import SwiftUI

struct HeroDecisionCard: View {
    let cardType: HeroCardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch cardType {
            case .bestTime(let friends, let time, let day):
                cardContent(
                    title: "Best Time Together 🎯",
                    subtitle: "\(day) \(time) with \(friends.joined(separator: ", "))",
                    actionText: "View Schedule →",
                    gradient: [Color("UTAustinOrange"), Color.orange]
                )
                
            case .dining(let hall, let status):
                cardContent(
                    title: "Eat Now 🍽️",
                    subtitle: "\(hall) — \(status)",
                    actionText: "View Menu →",
                    gradient: [Color.green, Color.blue]
                )
                
            case .gradeScenario(let course, let requirement):
                cardContent(
                    title: "Grade Check 📊",
                    subtitle: "\(course)\n\(requirement)",
                    actionText: "Calculate →",
                    gradient: [Color.red, Color.orange]
                )
                
            case .studyNow(let todayMinutes, _):
                cardContent(
                    title: "Keep it up! ⏱️",
                    subtitle: "You studied \(todayMinutes)m today. Let's hit the goal!",
                    actionText: "Start Timer →",
                    gradient: [Color.purple, Color.blue]
                )
                
            case .addFriends:
                cardContent(
                    title: "Start Here 👋",
                    subtitle: "Connect with friends to match schedules.",
                    actionText: "Add Friends →",
                    gradient: [Color.gray, Color.black]
                )
                
            case .shareSchedule:
                cardContent(
                    title: "Share Timetable 📅",
                    subtitle: "Let your friends know when you're free.",
                    actionText: "Share Now →",
                    gradient: [Color("UTAustinOrange"), Color.red]
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
    
    @ViewBuilder
    private func cardContent(title: String, subtitle: String, actionText: String, gradient: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer().frame(height: 10)
            
            Button(action: {
                // TODO: 각 카드에 맞는 네비게이션 액션 연결
            }) {
                Text(actionText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
            }
        }
    }
}
