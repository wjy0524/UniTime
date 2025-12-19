//
//  DashboardView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import Charts
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var gpaVM: GPAViewModel  // 🔥 실제 GPA 데이터 사용
    @EnvironmentObject var eventVM: EventViewModel  // 🔥 실제 이벤트 데이터 사용
    @StateObject private var notificationVM = NotificationViewModel()
    @StateObject private var studySessionManager = StudySessionManager()  // 🔥 Study Tracker
    @ObservedObject private var friendsManager = FriendsManager.shared  // 🔥 Unified Friends
    @State private var showingNotifications = false
    @State private var username: String = ""

    // MARK: - Static Data (식단/스터디)

    let diningMenu = [
        "Panda Express: Orange Chicken",
        "Jester City Limits: Pasta Bar",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    friendsCard  // 🔥 Unified Friends Section
                    todayScheduleCard
                    gpaCard  // 🔥 실제 GPA 반영됨
                    diningCard
                    quickActions
                    weeklyChartCard
                    sharePreviewCard
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                gpaVM.fetchCourses()  // 🔥 GPA 데이터 로드
                eventVM.startListening()  // 🔥 이벤트 데이터 로드
                notificationVM.startListening()  // 🔥 알림 데이터 로드
                studySessionManager.startListening()  // 🔥 스터디 데이터 로드
                friendsManager.startListening()  // 🔥 Friends 데이터 로드
                fetchUsername()  // 🔥 사용자 이름 로드
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationView()
            }
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - HEADER
////////////////////////////////////////////////////////////

extension DashboardView {
    var headerSection: some View {
        HStack(alignment: .center) {

            // LEFT — Greeting / Date
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingMessage())
                    .font(.system(size: 28, weight: .bold))
                Text(formattedDate())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // RIGHT — Notification Button
            Button {
                showingNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    headerIcon(system: "heart")

                    if notificationVM.unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 18, height: 18)

                            Text("\(min(notificationVM.unreadCount, 99))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 8, y: -8)
                    }
                }
            }
            .buttonStyle(.plain)

            // RIGHT — Search Button
            NavigationLink {
                SearchUserView()
            } label: {
                headerIcon(system: "magnifyingglass")
            }

            // RIGHT — Settings Button
            NavigationLink {
                SettingsView()
            } label: {
                headerIcon(system: "gearshape.fill")
            }

            // RIGHT — Profile Button
            NavigationLink {
                PublicProfileView(targetUid: Auth.auth().currentUser?.uid ?? "")
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("UTAustinOrange").opacity(0.8),
                                    Color.orange.opacity(0.6),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: .black.opacity(0.15), radius: 5, y: 3)

                    Image(systemName: "person.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
    }

}

////////////////////////////////////////////////////////////
// MARK: - TODAY’S SCHEDULE
////////////////////////////////////////////////////////////

extension DashboardView {
    var todayScheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Schedule")
                .font(.headline)

            if todaysEvents.isEmpty {
                Text("No events today 🎉")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 8)
            } else {
                ForEach(todaysEvents) { event in
                    HStack(spacing: 12) {
                        // Time
                        Text(formatEventTime(event.date))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(width: 90, alignment: .leading)
                            .foregroundColor(.secondary)

                        // Event info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if !event.location.isEmpty {
                                Text(event.location)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Color indicator
                        Circle()
                            .fill(Color(hexStr: event.colorHex) ?? .orange)
                            .frame(width: 10, height: 10)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background((Color(hexStr: event.colorHex) ?? .orange).opacity(0.1))
                    .cornerRadius(8)
                }
            }

            NavigationLink(destination: CalendarView()) {
                Text("Open Full Calendar →")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    // MARK: - Helper: Today's Events

    var todaysEvents: [Event] {
        let calendar = Calendar.current
        return eventVM.events.filter { event in
            calendar.isDate(event.date, inSameDayAs: Date())
        }
    }

    func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

////////////////////////////////////////////////////////////
// MARK: - FRIENDS CARD
////////////////////////////////////////////////////////////

extension DashboardView {
    var friendsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Friends")
                    .font(.headline)

                Spacer()

                NavigationLink(destination: FriendsView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            if friendsManager.friendRequests.isEmpty && friendsManager.friends.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.5))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("No friends yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Start connecting with people!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    NavigationLink(destination: SearchFriendsView(friendsManager: friendsManager)) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 8)
            } else {
                // Friend Requests
                if !friendsManager.friendRequests.isEmpty {
                    NavigationLink(
                        destination: FriendRequestsListView(friendsManager: friendsManager)
                    ) {
                        HStack {
                            Image(systemName: "envelope.badge.fill")
                                .foregroundColor(.orange)

                            Text(
                                "\(friendsManager.friendRequests.count) friend request\(friendsManager.friendRequests.count == 1 ? "" : "s")"
                            )
                            .font(.subheadline)
                            .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                // Friends Summary
                HStack(spacing: 20) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                        Text("\(friendsManager.friends.count)")
                            .font(.headline)
                        Text("Friends")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: SearchFriendsView(friendsManager: friendsManager)) {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                            Text("Find More")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

////////////////////////////////////////////////////////////
// MARK: - GPA CARD
////////////////////////////////////////////////////////////

extension DashboardView {
    var gpaCard: some View {

        let gpa = gpaVM.overallGPA
        let credits = gpaVM.totalCompletedCredits

        return VStack(alignment: .leading, spacing: 12) {
            Text("GPA Summary")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Current GPA")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.2f", gpa))
                        .font(.largeTitle)
                        .bold()
                }
                Spacer()

                Chart {
                    SectorMark(
                        angle: .value("Progress", gpa / 4.0),
                        innerRadius: .ratio(0.7),
                        angularInset: 2
                    )
                    .foregroundStyle(.blue.opacity(0.8))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(width: 100, height: 100)
            }

            Text("Completed Credits: \(credits)")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

}

////////////////////////////////////////////////////////////
// MARK: - DINING CARD
////////////////////////////////////////////////////////////

extension DashboardView {
    var diningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dining Today")
                .font(.headline)

            ForEach(diningMenu, id: \.self) { menu in
                HStack {
                    Text(menu)
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            NavigationLink(destination: DiningHomeView()) {
                Text("View Full Dining Menu →")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

////////////////////////////////////////////////////////////
// MARK: - QUICK ACTIONS
////////////////////////////////////////////////////////////

extension DashboardView {
    var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                quickActionItem("📘", "GPA") { GPAFullView() }
                quickActionItem("🍽", "Dining") { DiningHomeView() }
                quickActionItem("📅", "Calendar") { CalendarView() }
                quickActionItem("⏱️", "Study") { StudyTrackerView() }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    func quickActionItem<Destination: View>(
        _ icon: String,
        _ title: String,
        destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            VStack(spacing: 8) {
                Text(icon).font(.largeTitle)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - WEEKLY STUDY CHART
////////////////////////////////////////////////////////////

extension DashboardView {
    var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Study Hours")
                .font(.headline)

            if studySessionManager.weeklyData.isEmpty
                || studySessionManager.weeklyData.allSatisfy({ $0.hours == 0 })
            {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No study data yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            } else {
                Chart(studySessionManager.weeklyData) { item in
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Hours", item.hours)
                    )
                    .foregroundStyle(.purple)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 150)
            }

            NavigationLink(destination: StudyTrackerView()) {
                Text("Track My Study →")
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

////////////////////////////////////////////////////////////
// MARK: - SHARE PREVIEW
////////////////////////////////////////////////////////////

extension DashboardView {
    var sharePreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Share Requests")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("• Looking for someone to share ECE 302 notes.")
                Text("• Anyone want to exchange M 408D review sheets?")
            }
            .foregroundColor(.secondary)

            NavigationLink(destination: ShareRequestsView()) {
                Text("View All →")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

////////////////////////////////////////////////////////////
// MARK: - HELPERS
////////////////////////////////////////////////////////////

extension DashboardView {
    func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = username.isEmpty ? "there" : username
        switch hour {
        case 5..<12: return "Good morning, \(name)"
        case 12..<18: return "Good afternoon, \(name)"
        default: return "Good evening, \(name)"
        }
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    func fetchUsername() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch username: \(error.localizedDescription)")
                return
            }

            if let data = snapshot?.data(),
                let fetchedUsername = data["username"] as? String
            {
                DispatchQueue.main.async {
                    self.username = fetchedUsername
                }
            }
        }
    }
}

func headerIcon(system: String) -> some View {
    Image(systemName: system)
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(Color("UTAustinOrange"))
        .frame(width: 44, height: 44)
        .background(
            Circle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        )
}
#Preview {
    NavigationStack {
        DashboardView()
    }
    .environmentObject(GPAViewModel())  // mock / sample GPA VM
    .environmentObject(EventViewModel())  // mock / sample Event VM
}
