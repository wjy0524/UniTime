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
                    todayScheduleCard
                    quickActionsGrid
                    gpaCard  // 🔥 실제 GPA 반영됨
                    diningCard
                    weeklyChartCard
                    sharePreviewCard
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
            .onAppear {
                gpaVM.fetchCourses()  // 🔥 GPA 데이터 로드
                eventVM.startListening()  // 🔥 이벤트 데이터 로드
                notificationVM.startListening()  // 🔥 알림 데이터 로드
                studySessionManager.startListening()  // 🔥 스터디 데이터 로드
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
        VStack(alignment: .leading, spacing: 12) {
            
            // 1️⃣ 1단: 로고(좌) + 아이콘(우)
            HStack(alignment: .center) {
                // 로고 (이미지 안에 글자가 포함되어 있다면 Text("UniTime")은 빼셔도 됩니다)
                Image("UniTimeLogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80) // 에타 로고는 생각보다 작고 심플합니다
                    .foregroundColor(Color("UTAustinOrange"))
                
                // 만약 로고 이미지에 글자가 없다면 아래 주석 해제해서 사용
                /*
                Text("UniTime")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color("UTAustinOrange"))
                */

                Spacer()
                
                // 우측 아이콘 3개
                HStack(spacing: 20) {
                    NavigationLink(destination: SearchUserView()) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22))
                    }
                    
                    Button { showingNotifications = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 22))
                            
                            if notificationVM.unreadCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    
                    NavigationLink(destination: PublicProfileView(targetUid: Auth.auth().currentUser?.uid ?? "")) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 24))
                    }
                }
                .foregroundColor(.primary)
            }
            
            // 2️⃣ 2단: 학교 이름 (아주 크게!)
            Text("UT Austin")
                .font(.system(size: 20, weight: .bold)) // 🔥 32~34 정도로 시원하게 키우세요
                .padding(.leading, 2) // 로고와 라인 살짝 맞추기
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}


////////////////////////////////////////////////////////////
// MARK: - CALENDAR INSIGHT BANNER
////////////////////////////////////////////////////////////

extension DashboardView {

    var todayScheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)

                Text("Today")
                    .font(.headline)
            }

            // 🔥 핵심 분기
            if !todaysEvents.isEmpty {

                // ✅ 오늘 일정 있음
                VStack(spacing: 8) {
                    ForEach(todaysEvents.prefix(3)) { event in
                        HStack {
                            Text(formatEventTime(event.date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .leading)

                            Text(event.title)
                                .font(.subheadline)
                                .lineLimit(1)

                            Spacer()
                        }
                    }

                    if todaysEvents.count > 3 {
                        Text("+ \(todaysEvents.count - 3) more event(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

            } else if let next = nextUpcomingEvent {

                // 🟡 오늘 없음 → 다음 일정
                VStack(alignment: .leading, spacing: 6) {
                    Text("Next: \(next.title)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(formattedUpcomingTime(next.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)


            } else {

                // ❌ 일정 아예 없음
                VStack(alignment: .leading, spacing: 6) {
                    Text("You're all clear today 🎉")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Take it easy or plan ahead.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer() // ✅ 카드 높이 안정화

            NavigationLink(destination: CalendarView()) {
                Text("Open Calendar →")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150) // ⭐️ 고정 높이
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}


extension DashboardView {

    var todaysEvents: [Event] {
        let calendar = Calendar.current
        return eventVM.events.filter {
            calendar.isDate($0.date, inSameDayAs: Date())
        }
    }
}

extension DashboardView {

    func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension DashboardView {
    
    func formattedRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension DashboardView {

    var nextUpcomingEvent: Event? {
        let now = Date()
        return eventVM.events
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
            .first
    }
}

extension DashboardView {

    func formattedUpcomingTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if calendar.isDateInToday(date) {
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "EEE h:mm a"
            return formatter.string(from: date)
        }
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
// MARK: - QUICK ACTIONS GRID (Portal Style)
////////////////////////////////////////////////////////////

extension DashboardView {

    var quickActionsGrid: some View {
        VStack(spacing: 16) {

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: 20
            ) {

                quickActionItem(
                    title: "Board",
                    systemImage: "bubble.left.and.bubble.right.fill",
                    color: .blue,
                    destination: BoardView()
                )

                quickActionItem(
                    title: "GPA",
                    systemImage: "chart.bar.fill",
                    color: .orange,
                    destination: GPAFullView()
                )

                quickActionItem(
                    title: "Dining",
                    systemImage: "fork.knife.circle.fill",
                    color: .green,
                    destination: DiningHomeView()
                )

                quickActionItem(
                    title: "Calendar",
                    systemImage: "calendar.circle.fill",
                    color: .red,
                    destination: CalendarView()
                )

                quickActionItem(
                    title: "Study",
                    systemImage: "book.circle.fill",
                    color: .indigo,
                    destination: StudyTrackerView()
                )

                quickActionItem(
                    title: "Marketplace",
                    systemImage: "cart.circle.fill",
                    color: .purple,
                    destination: MarketplaceView()
                )

                quickActionItem(
                    title: "Timetable",
                    systemImage: "clock.circle.fill",
                    color: .teal,
                    destination: TimetableView()
                )
            }
        }
        .padding(.horizontal)
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

extension DashboardView {

    func quickActionItem<Destination: View>(
        title: String,
        systemImage: String,
        color: Color,
        destination: Destination
    ) -> some View {

        NavigationLink(destination: destination) {
            VStack(spacing: 8) {

                Image(systemName: systemImage)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .frame(height: 32)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
