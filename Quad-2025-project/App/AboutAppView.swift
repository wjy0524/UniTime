//
//  AboutAppView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import SwiftUI

struct AboutAppView: View {

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // MARK: - Header
                VStack(spacing: 12) {
                    Image("UniTimeLogo") // 앱 아이콘 or 브랜드 이미지
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: AppConstants.Layout.avatarSizeMedium,
                            height: AppConstants.Layout.avatarSizeMedium
                        )
                        .cornerRadius(20)
                        .shadow(radius: 6)
                        .foregroundColor(Color("UTAustinOrange"))

                    Text("UniTime")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Your all-in-one campus companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)

                // MARK: - Description Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("About UniTime")
                        .font(.headline)

                    Text("""
UniTime is an AI-powered personal campus assistant built to simplify student life at UT Austin.

Ask anything about classes, schedules, dining, events, or campus life — UniTime’s AI delivers instant, personalized answers tailored to your needs.

Beyond AI, UniTime brings scheduling, GPA tracking, dining, and community features into one seamless campus experience, helping you stay organized, connected, and focused on what matters most.

""")
                    .font(.body)
                    .foregroundColor(.primary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)

                // MARK: - Feature Highlights
                VStack(alignment: .leading, spacing: 16) {
                    Text("What you can do")
                        .font(.headline)
                    FeatureRow(
                        icon: "sparkles",
                        title: "AI Campus Assistant",
                        description: "Ask anything about UT Austin — classes, schedules, dining, events, or campus life — and get instant, personalized answers."
                    )

                    FeatureRow(icon: "calendar", title: "Smart Scheduling",
                               description: "Manage classes, events, and shared timetables effortlessly.")

                    FeatureRow(icon: "chart.bar.fill", title: "GPA & Grade Tracking",
                               description: "Track your academic progress with clarity and insights.")

                    FeatureRow(icon: "fork.knife", title: "Dining & Campus Info",
                               description: "Explore dining menus and campus resources in one place.")

                    FeatureRow(icon: "bubble.left.and.bubble.right.fill", title: "Student Community",
                               description: "Connect with other students through posts and discussions.")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)

                // MARK: - Footer
                VStack(spacing: 6) {
                    Text("Version 1.0.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text("© 2026 UniTime")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("UTAustinOrange"))
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
