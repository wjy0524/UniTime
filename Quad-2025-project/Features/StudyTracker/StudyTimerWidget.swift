//
//  StudyTimerWidget.swift
//  Quad-2025-project
//
//  Compact widget view for quick study timer access from Dashboard
//

import SwiftUI

struct StudyTimerWidget: View {
    @ObservedObject var sessionManager: StudySessionManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color("UTAustinOrange"))
                    Text("Study Timer")
                        .font(.headline)
                }

                Spacer()

                if sessionManager.isStudying {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Timer Display
            if sessionManager.currentSession != nil {
                VStack(spacing: 8) {
                    Text(sessionManager.formattedTime(sessionManager.elapsedTime))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    if sessionManager.isStudying {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption2)
                                .foregroundColor(Color("UTAustinOrange"))
                            Text(
                                "\(sessionManager.blockedApps.filter { $0.isBlocked }.count) apps blocked"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Paused")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                // Control Buttons
                HStack(spacing: 12) {
                    if sessionManager.isStudying {
                        Button {
                            sessionManager.pauseStudySession()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pause.fill")
                                    .font(.caption)
                                Text("Pause")
                                    .font(.caption)
                                    .bold()
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    } else {
                        Button {
                            sessionManager.resumeStudySession()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.caption)
                                Text("Resume")
                                    .font(.caption)
                                    .bold()
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    }

                    Button {
                        sessionManager.endStudySession()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                                .font(.caption)
                            Text("End")
                                .font(.caption)
                                .bold()
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                }
            } else {
                // Start Button
                VStack(spacing: 12) {
                    Text("Ready to focus?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        sessionManager.startStudySession()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                            Text("Start Studying")
                                .font(.subheadline)
                                .bold()
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color("UTAustinOrange"), Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }

            // Quick Stats
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(formatTime(sessionManager.getTodayStudyTime()))
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Color("UTAustinOrange"))
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text(formatTime(sessionManager.getWeekStudyTime()))
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.blue)
                    Text("This Week")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text("\(sessionManager.sessions.filter { !$0.isActive }.count)")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.green)
                    Text("Sessions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    // MARK: - Helper Functions

    func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return "0m"
        }
    }
}

#Preview {
    StudyTimerWidget(sessionManager: StudySessionManager())
        .padding()
}
