//
//  TimetableSharingHubView.swift
//  Quad-2025-project
//
//  Created for unified timetable sharing interface
//

import FirebaseAuth
import SwiftUI

struct TimetableSharingHubView: View {
    @StateObject private var shareViewModel = TimetableShareViewModel.shared
    @State private var selectedTab = 0
    @State private var sharedTimetables: [TimetableShareRequest] = []
    @State private var isLoadingShared: Bool = true
    @State private var selectedTimetable: TimetableShareRequest?
    @State private var timetableToDelete: TimetableShareRequest?
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Picker
                HStack(spacing: 0) {
                    TabButton(
                        title: "Requests",
                        badge: shareViewModel.shareRequests.count,
                        isSelected: selectedTab == 0
                    ) {
                        withAnimation {
                            selectedTab = 0
                        }
                    }

                    TabButton(
                        title: "Shared",
                        badge: nil,
                        isSelected: selectedTab == 1
                    ) {
                        withAnimation {
                            selectedTab = 1
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Divider()

                // Tab Content
                TabView(selection: $selectedTab) {
                    RequestsTabView()
                        .tag(0)

                    SharedTimetablesTabView(
                        sharedTimetables: $sharedTimetables,
                        isLoading: $isLoadingShared,
                        selectedTimetable: $selectedTimetable,
                        timetableToDelete: $timetableToDelete,
                        showingDeleteConfirmation: $showingDeleteConfirmation
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Timetable Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSharedTimetables()
            }
            .sheet(item: $selectedTimetable) { timetable in
                TimetableDetailView(
                    shareRequest: timetable,
                    onDelete: {
                        timetableToDelete = timetable
                        showingDeleteConfirmation = true
                    }
                )
            }
            .alert("Delete Shared Timetable", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let timetable = timetableToDelete {
                        deleteSharedTimetable(timetable)
                    }
                }
            } message: {
                Text("Are you sure you want to remove this shared timetable?")
            }
        }
    }

    private func loadSharedTimetables() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoadingShared = false
            return
        }

        shareViewModel.loadSharedTimetables(userId: userId) { result in
            isLoadingShared = false
            switch result {
            case .success(let timetables):
                sharedTimetables = timetables
            case .failure:
                sharedTimetables = []
            }
        }
    }

    private func deleteSharedTimetable(_ timetable: TimetableShareRequest) {
        shareViewModel.deleteSharedTimetable(timetable) { success in
            if success {
                sharedTimetables.removeAll { $0.id == timetable.id }
                selectedTimetable = nil
            }
        }
    }
}

// MARK: - Tab Button Component
struct TabButton: View {
    let title: String
    let badge: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)

                    if let count = badge, count > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)

                            Text("\(min(count, 99))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .foregroundColor(isSelected ? Color("UTAustinOrange") : .secondary)

                Rectangle()
                    .fill(isSelected ? Color("UTAustinOrange") : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Requests Tab
struct RequestsTabView: View {
    @StateObject private var viewModel = TimetableShareViewModel.shared

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if viewModel.shareRequests.isEmpty {
                requestsEmptyState
            } else {
                requestList
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

    var requestsEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Requests")
                .font(.title2)
                .bold()

            Text("You don't have any timetable share requests at the moment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var requestList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.shareRequests) { request in
                    RequestCard(request: request)
                }
            }
            .padding()
        }
    }
}

// MARK: - Request Card
struct RequestCard: View {
    let request: TimetableShareRequest
    @StateObject private var viewModel = TimetableShareViewModel.shared
    @State private var showingPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color("UTAustinOrange").opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(request.fromUsername.prefix(1).uppercased())
                            .font(.title3)
                            .bold()
                            .foregroundColor(Color("UTAustinOrange"))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.fromUsername)
                        .font(.headline)

                    Text("wants to share their timetable")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(timeAgo(from: request.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            HStack(spacing: 12) {
                Button {
                    showingPreview = true
                } label: {
                    Label("Preview", systemImage: "eye")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }

                Button {
                    viewModel.declineShareRequest(request)
                } label: {
                    Label("Decline", systemImage: "xmark")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }

                Button {
                    viewModel.acceptShareRequest(request)
                } label: {
                    Label("Accept", systemImage: "checkmark")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .sheet(isPresented: $showingPreview) {
            TimetablePreviewView(request: request)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Shared Timetables Tab
struct SharedTimetablesTabView: View {
    @Binding var sharedTimetables: [TimetableShareRequest]
    @Binding var isLoading: Bool
    @Binding var selectedTimetable: TimetableShareRequest?
    @Binding var timetableToDelete: TimetableShareRequest?
    @Binding var showingDeleteConfirmation: Bool

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading shared timetables...")
            } else if sharedTimetables.isEmpty {
                sharedEmptyState
            } else {
                sharedTimetablesList
            }
        }
    }

    var sharedEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Shared Timetables")
                .font(.title2)
                .bold()

            Text(
                "You haven't accepted any timetable shares yet. When friends share their timetables with you, they'll appear here."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var sharedTimetablesList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(sharedTimetables) { timetable in
                    SharedTimetableCard(
                        timetable: timetable,
                        onTap: {
                            selectedTimetable = timetable
                        },
                        onDelete: {
                            timetableToDelete = timetable
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Shared Timetable Card
struct SharedTimetableCard: View {
    let timetable: TimetableShareRequest
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color("UTAustinOrange").opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(timetable.fromUsername.prefix(1).uppercased())
                            .font(.title3)
                            .bold()
                            .foregroundColor(Color("UTAustinOrange"))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(timetable.fromUsername)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(timetable.timetableCourses.count) courses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Shared \(timeAgo(from: timetable.timestamp))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Timetable Preview
struct TimetablePreviewView: View {
    let request: TimetableShareRequest
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(request.fromUsername)'s Timetable")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    ForEach(request.timetableCourses) { course in
                        CoursePreviewCard(course: course)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Course Preview Card
struct CoursePreviewCard: View {
    let course: TimetableCourse
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(course.color)
                    .frame(width: 12, height: 12)

                Text(course.code)
                    .font(.headline)

                Spacer()
            }

            Text(course.name)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !course.instructor.isEmpty {
                Label(course.instructor, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !course.location.isEmpty {
                Label(course.location, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if course.isAsync {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.caption2)
                        .foregroundColor(course.color)

                    Text("Async - No fixed schedule")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(course.times) { time in
                        HStack(spacing: 6) {
                            Text(days[time.day])
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(course.color.opacity(0.2))
                                .cornerRadius(6)

                            Text("\(formatTime(time.startTime)) - \(formatTime(time.endTime))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    private func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let suffix = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)

        if minute == 0 {
            return "\(displayHour)\(suffix)"
        }
        return String(format: "%d:%02d%@", displayHour, minute, suffix)
    }
}

// MARK: - Timetable Detail View
struct TimetableDetailView: View {
    let shareRequest: TimetableShareRequest
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(shareRequest.timetableCourses) { course in
                        CoursePreviewCard(course: course)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("\(shareRequest.fromUsername)'s Timetable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}
