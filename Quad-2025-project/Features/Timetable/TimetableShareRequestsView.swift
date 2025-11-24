//
//  TimetableShareRequestsView.swift
//  Quad-2025-project
//
//  Created on Timetable Sharing Feature Implementation
//

import SwiftUI

struct TimetableShareRequestsView: View {
    @StateObject private var viewModel = TimetableShareViewModel.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if viewModel.shareRequests.isEmpty {
                    emptyStateView
                } else {
                    requestList
                }
            }
            .navigationTitle("Timetable Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $viewModel.showingSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Share Requests")
                .font(.title2)
                .bold()

            Text("You'll see timetable share requests here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Request List

    var requestList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.shareRequests) { request in
                    ShareRequestCard(
                        request: request,
                        onAccept: {
                            if let id = request.id {
                                viewModel.acceptShareRequest(id)
                            }
                        },
                        onDecline: {
                            if let id = request.id {
                                viewModel.declineShareRequest(id)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Share Request Card

struct ShareRequestCard: View {
    let request: TimetableShareRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info
            HStack(spacing: 12) {
                // Profile Image
                if let imageURL = request.fromUserProfileImage, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(request.fromUsername.prefix(1).uppercased()))
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.fromUsername)
                        .font(.headline)

                    Text("wants to share their timetable")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(timeAgo(from: request.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Course count and preview toggle
            HStack {
                Text(
                    "\(request.timetableCourses.count) course\(request.timetableCourses.count == 1 ? "" : "s")"
                )
                .font(.subheadline)
                .foregroundColor(.blue)

                Spacer()

                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Hide" : "Preview")
                            .font(.caption)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }

            // Expanded course list
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(request.timetableCourses) { course in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(course.color)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(course.code) - \(course.name)")
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Text(formatCourseTimes(course.times))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(.top, 4)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }

                Button(action: onAccept) {
                    Text("Accept")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    func formatCourseTimes(_ times: [CourseTime]) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        let grouped = Dictionary(grouping: times, by: { $0.day })
        let sorted = grouped.sorted { $0.key < $1.key }

        return sorted.map { day, times in
            let dayName = days[day]
            let timeStrings = times.map { time in
                formatTime(time.startTime) + "-" + formatTime(time.endTime)
            }.joined(separator: ", ")
            return "\(dayName): \(timeStrings)"
        }.joined(separator: " • ")
    }

    func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        if minute == 0 {
            return "\(displayHour)\(suffix)"
        }
        return String(format: "%d:%02d%@", displayHour, minute, suffix)
    }

    func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

struct TimetableShareRequestsView_Previews: PreviewProvider {
    static var previews: some View {
        TimetableShareRequestsView()
    }
}
