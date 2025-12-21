//
//  StudyTrackerView.swift
//  Quad-2025-project
//
//  Main view for study tracking with timer and app blocking
//

import Charts
import FamilyControls
import SwiftUI

struct StudyTrackerView: View {
    @StateObject private var sessionManager = StudySessionManager()
    @StateObject private var friendsManager = StudyFriendsManager()
    @State private var showBlockedApps = false
    @State private var showHistory = false
    @State private var showScreenTimePrompt = false
    @State private var showAppPicker = false
    @State private var showStudyFriends = false
    @State private var showPrivacySettings = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Timer Card
                    timerCard

                    // Statistics Cards
                    statisticsSection

                    // Weekly Chart
                    weeklyChartCard

                    // Quick Actions
                    quickActionsSection

                    // Recent Sessions
                    recentSessionsCard
                }
                .padding()
            }
            .navigationTitle("Study Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showStudyFriends = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(Color("UTAustinOrange"))

                            if friendsManager.friendRequests.count > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 18, height: 18)

                                    Text("\(min(friendsManager.friendRequests.count, 99))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showBlockedApps) {
                BlockedAppsSettingsView(sessionManager: sessionManager)
            }
            .sheet(isPresented: $showHistory) {
                StudyHistoryView(sessionManager: sessionManager)
            }
            .sheet(isPresented: $showScreenTimePrompt) {
                ScreenTimeAuthorizationView(sessionManager: sessionManager)
            }
            .sheet(isPresented: $showAppPicker) {
                AppPickerView(selection: $sessionManager.selectedAppsForBlocking)
            }
            .sheet(isPresented: $showStudyFriends) {
                StudyFriendsView()
            }
            .sheet(isPresented: $showPrivacySettings) {
                StudyPrivacySettingsView()
            }
            .onAppear {
                sessionManager.requestNotificationPermission()
            }
        }
    }

    // MARK: - Timer Card

    var timerCard: some View {
        VStack(spacing: 20) {
            // Timer Display
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color("UTAustinOrange").opacity(0.3),
                                Color.orange.opacity(0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 15
                    )
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: sessionManager.isStudying ? 1.0 : 0.0)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color("UTAustinOrange"),
                                Color.orange,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: sessionManager.isStudying)

                VStack(spacing: 8) {
                    Text(sessionManager.formattedTime(sessionManager.elapsedTime))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(sessionManager.isStudying ? "Studying..." : "Not Studying")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Control Buttons
            HStack(spacing: 16) {
                if !sessionManager.isStudying && sessionManager.currentSession == nil {
                    // Start Button
                    Button {
                        // Check Screen Time authorization before starting
                        if sessionManager.isScreenTimeAuthorized {
                            sessionManager.startStudySession()
                        } else {
                            showScreenTimePrompt = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start")
                        }
                        .font(.headline)
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
                } else if sessionManager.isStudying {
                    // Pause Button
                    Button {
                        sessionManager.pauseStudySession()
                    } label: {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text("Pause")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }

                    // Stop Button
                    Button {
                        sessionManager.endStudySession()
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("End")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                } else {
                    // Resume Button
                    Button {
                        sessionManager.resumeStudySession()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }

                    // Stop Button
                    Button {
                        sessionManager.endStudySession()
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("End")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)

            // Blocked Apps Indicator
            if sessionManager.isStudying {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(Color("UTAustinOrange"))
                    Text("\(sessionManager.blockedApps.filter { $0.isBlocked }.count) apps blocked")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color("UTAustinOrange").opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    // MARK: - Statistics Section

    var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                statCard(
                    title: "Today",
                    value: sessionManager.formattedTime(sessionManager.getTodayStudyTime()),
                    icon: "calendar",
                    color: .blue
                )

                statCard(
                    title: "This Week",
                    value: sessionManager.formattedTime(sessionManager.getWeekStudyTime()),
                    icon: "calendar.badge.clock",
                    color: .purple
                )
            }

            HStack(spacing: 16) {
                statCard(
                    title: "Average/Day",
                    value: sessionManager.formattedTime(sessionManager.getAverageStudyTime()),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )

                statCard(
                    title: "Total Sessions",
                    value: "\(sessionManager.sessions.filter { !$0.isActive }.count)",
                    icon: "checkmark.circle",
                    color: Color("UTAustinOrange")
                )
            }
        }
    }

    func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
        .cornerRadius(12)
    }

    // MARK: - Weekly Chart Card

    var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)

            if sessionManager.weeklyData.isEmpty
                || sessionManager.weeklyData.allSatisfy({ $0.hours == 0 })
            {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No study data yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Start studying to see your progress!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                Chart(sessionManager.weeklyData) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Hours", item.hours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("UTAustinOrange"), Color.orange],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let day = value.as(String.self) {
                                Text(day)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    // MARK: - Quick Actions

    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        showBlockedApps = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "app.badge.fill")
                                .font(.title2)
                            Text("Blocked Apps")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }

                    Button {
                        showHistory = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                            Text("History")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                    }

                    Button {
                        showPrivacySettings = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill")
                                .font(.title2)
                            Text("Privacy")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    }
                }

                // Screen Time & App Picker
                HStack(spacing: 12) {
                    Button {
                        showScreenTimePrompt = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(
                                systemName: sessionManager.isScreenTimeAuthorized
                                    ? "checkmark.shield.fill" : "shield.slash.fill"
                            )
                            .font(.title2)
                            Text(
                                sessionManager.isScreenTimeAuthorized ? "Authorized" : "Screen Time"
                            )
                            .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            sessionManager.isScreenTimeAuthorized
                                ? Color.green.opacity(0.1) : Color.orange.opacity(0.1)
                        )
                        .foregroundColor(sessionManager.isScreenTimeAuthorized ? .green : .orange)
                        .cornerRadius(12)
                    }

                    Button {
                        showAppPicker = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .font(.title2)
                            Text("Select Apps")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink.opacity(0.1))
                        .foregroundColor(.pink)
                        .cornerRadius(12)
                    }
                    .disabled(!sessionManager.isScreenTimeAuthorized)
                    .opacity(sessionManager.isScreenTimeAuthorized ? 1.0 : 0.5)
                }

                // Study Friends
                Button {
                    showStudyFriends = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.title3)
                            Text("Study Friends")
                                .font(.subheadline)
                                .bold()
                            Spacer()
                            if friendsManager.friendRequests.count > 0 {
                                Text("\(friendsManager.friendRequests.count)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    // MARK: - Recent Sessions Card

    var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sessions")
                    .font(.headline)
                Spacer()
                Button("See All") {
                    showHistory = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            if sessionManager.sessions.filter({ !$0.isActive }).isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No study sessions yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(Array(sessionManager.sessions.filter { !$0.isActive }.prefix(3))) {
                    session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.formattedDuration)
                                .font(.subheadline)
                                .bold()
                            Text(formatDate(session.startTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption)
                                .foregroundColor(Color("UTAustinOrange"))
                            Text("\(session.blockedApps.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    // MARK: - Helper Functions

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Screen Time Authorization View

struct ScreenTimeAuthorizationView: View {
    @ObservedObject var sessionManager: StudySessionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color("UTAustinOrange").opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 60))
                            .foregroundColor(Color("UTAustinOrange"))
                    }
                    .padding(.top)

                    // Title
                    VStack(spacing: 8) {
                        Text("Screen Time Access")
                            .font(.title)
                            .bold()

                        Text("Enable app blocking to stay focused")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Status
                    HStack {
                        Image(
                            systemName: sessionManager.isScreenTimeAuthorized
                                ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                        )
                        .foregroundColor(sessionManager.isScreenTimeAuthorized ? .green : .orange)

                        Text(
                            sessionManager.isScreenTimeAuthorized ? "Authorized" : "Not Authorized"
                        )
                        .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        sessionManager.isScreenTimeAuthorized
                            ? Color.green.opacity(0.1) : Color.orange.opacity(0.1)
                    )
                    .cornerRadius(12)

                    // Info
                    VStack(alignment: .leading, spacing: 16) {
                        infoRow(icon: "1.circle.fill", text: "Tap 'Request Authorization' below")
                        infoRow(icon: "2.circle.fill", text: "Review the permission prompt")
                        infoRow(icon: "3.circle.fill", text: "Approve Screen Time access")
                        infoRow(icon: "4.circle.fill", text: "Select apps to block when studying")
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
                    .cornerRadius(16)

                    // Authorization Button
                    if !sessionManager.isScreenTimeAuthorized {
                        Button {
                            Task {
                                await sessionManager.requestScreenTimeAuthorization()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                Text("Request Authorization")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color("UTAustinOrange"), Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Important Note")
                                .font(.headline)
                        }

                        Text(
                            "Screen Time authorization is required to physically block apps. Without it, the app will track your study time but won't restrict app usage."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("App Blocking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("UTAustinOrange"))
                }
            }
        }
    }

    func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("UTAustinOrange"))
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - App Picker View

struct AppPickerView: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Apps to Block")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(Color("UTAustinOrange"))
                    }
                }
        }
    }
}

#Preview {
    StudyTrackerView()
}
