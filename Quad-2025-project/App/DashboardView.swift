//
//  DashboardView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var gpaVM: GPAViewModel   // 🔥 실제 GPA 데이터 사용
    
    // MARK: - Static Data (일정/식단/스터디)
    let todaysEvents: [(time: String, title: String)] = [
        ("10:00 AM", "ECE 312 Lecture"),
        ("4:00 PM", "Team Project Meeting"),
        ("7:00 PM", "Study Session")
    ]
    
    let diningMenu = [
        "Panda Express: Orange Chicken",
        "Jester City Limits: Pasta Bar"
    ]
    
    let studyData: [StudyHours] = [
        .init(day: "Mon", hours: 2.5),
        .init(day: "Tue", hours: 3.0),
        .init(day: "Wed", hours: 1.0),
        .init(day: "Thu", hours: 2.0),
        .init(day: "Fri", hours: 4.0),
        .init(day: "Sat", hours: 1.5),
        .init(day: "Sun", hours: 3.5)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    todayScheduleCard
                    gpaCard     // 🔥 실제 GPA 반영됨
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
                gpaVM.fetchCourses()   // 🔥 GPA 데이터 로드
            }
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - HEADER
////////////////////////////////////////////////////////////

extension DashboardView {
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingMessage())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(formattedDate())
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.blue)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

////////////////////////////////////////////////////////////
// MARK: - TODAY’S SCHEDULE
////////////////////////////////////////////////////////////

extension DashboardView {
    var todayScheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s Schedule")
                .font(.headline)
            
            if todaysEvents.isEmpty {
                Text("No events today 🎉")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(todaysEvents, id: \.time) { event in
                    HStack {
                        Text(event.time)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(width: 90, alignment: .leading)
                        
                        Text(event.title)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            NavigationLink(destination: CalendarKitView()) {
                Text("Open Full Calendar →")
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
                HStack { Text(menu); Spacer() }
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
                quickActionItem("📅", "Calendar") { CalendarKitView() }
                quickActionItem("🤝", "Share") { ShareRequestsView() }
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

struct StudyHours: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
}

extension DashboardView {
    var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Study Hours")
                .font(.headline)
            
            Chart(studyData) { item in
                LineMark(
                    x: .value("Day", item.day),
                    y: .value("Hours", item.hours)
                )
                .foregroundStyle(.purple)
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 150)
            
            Button("Track My Study →") {}
                .foregroundColor(.blue)
                .font(.subheadline)
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
        switch hour {
        case 5..<12: return "Good morning, Jaeyeon"
        case 12..<18: return "Good afternoon, Jaeyeon"
        default: return "Good evening, Jaeyeon"
        }
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
}


