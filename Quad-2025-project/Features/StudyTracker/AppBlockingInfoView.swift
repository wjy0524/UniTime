//
//  AppBlockingInfoView.swift
//  Quad-2025-project
//
//  Information view about app blocking and Screen Time integration
//

import SwiftUI
import UIKit

struct AppBlockingInfoView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Icon
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("UTAustinOrange").opacity(0.2),
                                            Color.orange.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color("UTAustinOrange"))
                        }
                        Spacer()
                    }
                    .padding(.top)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How App Blocking Works")
                            .font(.title)
                            .bold()

                        Text("Stay focused during your study sessions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Features Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)

                        featureRow(
                            icon: "app.badge.fill",
                            title: "Select Apps to Block",
                            description: "Choose which apps you want to restrict during study time"
                        )

                        featureRow(
                            icon: "timer",
                            title: "Automatic Timer",
                            description:
                                "Apps are blocked only when you're in an active study session"
                        )

                        featureRow(
                            icon: "chart.bar.fill",
                            title: "Track Your Progress",
                            description: "See how your study time improves with fewer distractions"
                        )

                        featureRow(
                            icon: "bell.badge.fill",
                            title: "Smart Reminders",
                            description:
                                "Get notifications to keep you motivated during study sessions"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
                    .cornerRadius(16)

                    // How it Works Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How It Works")
                            .font(.headline)

                        stepRow(
                            number: 1,
                            title: "Select Apps",
                            description: "Go to Settings and choose which apps to block"
                        )

                        stepRow(
                            number: 2,
                            title: "Start Studying",
                            description: "Tap the Start button to begin your study session"
                        )

                        stepRow(
                            number: 3,
                            title: "Stay Focused",
                            description: "The timer tracks your study time automatically"
                        )

                        stepRow(
                            number: 4,
                            title: "End Session",
                            description:
                                "Tap End when you're done to unlock apps and save your progress"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
                    .cornerRadius(16)

                    // Integration Notice
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Screen Time Integration")
                                .font(.headline)
                        }

                        Text(
                            "For full app blocking functionality, this app can integrate with iOS Screen Time. You can manually set up app limits in Settings > Screen Time during your study sessions."
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        Button {
                            if let url = URL(string: "App-prefs:root=SCREEN_TIME") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Screen Time Settings")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)

                    // Tips Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips for Success")
                            .font(.headline)

                        tipRow(
                            icon: "🎯",
                            text:
                                "Set realistic study goals and gradually increase your session length"
                        )
                        tipRow(icon: "📱", text: "Put your phone in another room for maximum focus")
                        tipRow(
                            icon: "⏰",
                            text: "Use the Pomodoro technique: 25 minutes study, 5 minutes break")
                        tipRow(
                            icon: "🎧", text: "Use white noise or study music if it helps you focus")
                        tipRow(
                            icon: "💪", text: "Stay consistent - even short daily sessions add up!")
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("App Blocking Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(Color("UTAustinOrange"))
                }
            }
        }
    }

    // MARK: - Feature Row

    func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color("UTAustinOrange"))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Step Row

    func stepRow(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("UTAustinOrange"))
                    .frame(width: 30, height: 30)

                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Tip Row

    func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
                .font(.title3)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AppBlockingInfoView()
}
