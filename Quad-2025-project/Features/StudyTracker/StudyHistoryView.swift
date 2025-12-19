//
//  StudyHistoryView.swift
//  Quad-2025-project
//
//  View for displaying all past study sessions with filtering and statistics
//

import SwiftUI

struct StudyHistoryView: View {
    @ObservedObject var sessionManager: StudySessionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedFilter: FilterOption = .all
    @State private var searchText = ""

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Statistics Header
                statisticsHeader

                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Sessions List
                if filteredSessions.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                            Section(header: Text(formatSectionDate(date))) {
                                ForEach(groupedSessions[date] ?? []) { session in
                                    sessionRow(session: session)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Study History")
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

    // MARK: - Statistics Header

    var statisticsHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(filteredSessions.count)")
                        .font(.title)
                        .bold()
                        .foregroundColor(Color("UTAustinOrange"))
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text(formatTotalTime(filteredSessions.reduce(0) { $0 + $1.duration }))
                        .font(.title)
                        .bold()
                        .foregroundColor(.blue)
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text(formatTotalTime(averageSessionTime))
                        .font(.title)
                        .bold()
                        .foregroundColor(.green)
                    Text("Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
    }

    // MARK: - Session Row

    func sessionRow(session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(Color("UTAustinOrange"))
                    Text(session.formattedDuration)
                        .font(.headline)
                        .bold()
                }

                Spacer()

                // Time
                Text(formatTime(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Blocked Apps Count
            if !session.blockedApps.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("\(session.blockedApps.count) apps blocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Date details
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatFullDate(session.startTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if let endTime = session.endTime {
                    Text("→")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatTime(endTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Study Sessions")
                .font(.title2)
                .bold()

            Text("Start studying to see your history here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Computed Properties

    var filteredSessions: [StudySession] {
        let completedSessions = sessionManager.sessions.filter { !$0.isActive }

        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .all:
            return completedSessions

        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
            return completedSessions.filter { session in
                session.startTime >= startOfDay && session.startTime < endOfDay
            }

        case .week:
            let weekday = calendar.component(.weekday, from: now)
            let daysFromMonday = (weekday + 5) % 7
            guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: now)
            else {
                return completedSessions
            }
            let weekStart = calendar.startOfDay(for: startOfWeek)
            return completedSessions.filter { session in
                session.startTime >= weekStart
            }

        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let startOfMonth = calendar.date(from: components) else {
                return completedSessions
            }
            return completedSessions.filter { session in
                session.startTime >= startOfMonth
            }
        }
    }

    var groupedSessions: [Date: [StudySession]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredSessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
    }

    var averageSessionTime: TimeInterval {
        guard !filteredSessions.isEmpty else { return 0 }
        let total = filteredSessions.reduce(0.0) { $0 + $1.duration }
        return total / Double(filteredSessions.count)
    }

    // MARK: - Helper Functions

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    func formatTotalTime(_ timeInterval: TimeInterval) -> String {
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
    StudyHistoryView(sessionManager: StudySessionManager())
}
