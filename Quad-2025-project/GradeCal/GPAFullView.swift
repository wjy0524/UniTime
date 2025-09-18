//
//  GPAFullView.swift
//  Quad-2025-project
//

import SwiftUI
import Charts

struct GPAFullView: View {
    @StateObject private var viewModel = GPAViewModel()
    @State private var selectedSemester: Semester = .freshmanFall
    @State private var showingAddCourse = false
    @State private var courseToEdit: Course? = nil

    var body: some View {
        List {
            // 🔹 학기 선택
            Section {
                semesterPicker
            }

            // 🔹 GPA 카드 & 트렌드
            if let gpaSummary = viewModel.gpaForSemester(selectedSemester) {
                Section {
                    summaryCards(for: gpaSummary)
                }

                Section {
                    gpaTrendChart
                }
            } else {
                Section {
                    Text("No data for \(selectedSemester.rawValue)")
                        .foregroundColor(.gray)
                        .font(.callout)
                }
            }

            // 🔹 과목 리스트
            Section(header: Text("Courses")) {
                ForEach(viewModel.coursesForSemester(selectedSemester)) { course in
                    CourseCard(course: course)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteCourse(course)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                courseToEdit = course
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
        .listStyle(.insetGrouped) // ✅ 스크롤 정상 & 깔끔
        .navigationTitle("GPA Calculator")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCourse = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("UTAustinOrange"))
                }
            }
        }
        .onAppear {
            viewModel.fetchCourses()
        }
        .sheet(isPresented: $showingAddCourse) {
            AddCourseView(viewModel: viewModel)
        }
        .sheet(item: $courseToEdit) { course in
            AddCourseView(viewModel: viewModel, courseToEdit: course)
        }
    }
}

// MARK: - Components
extension GPAFullView {
    
    private var semesterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Semester.allCases) { semester in
                    Text(semester.rawValue)
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            selectedSemester == semester
                            ? Color("UTAustinOrange").opacity(0.15)
                            : Color(.systemGray6)
                        )
                        .foregroundColor(
                            selectedSemester == semester
                            ? Color("UTAustinOrange")
                            : .primary
                        )
                        .cornerRadius(12)
                        .onTapGesture {
                            selectedSemester = semester
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func summaryCards(for gpaSummary: GPASummary) -> some View {
        HStack(spacing: 14) {
            SummaryCard(
                title: "Overall GPA",
                value: String(format: "%.2f", gpaSummary.overallGPA),
                subtitle: "/ 4.0",
                color: Color("UTAustinOrange")
            )
            SummaryCard(
                title: "Major GPA",
                value: String(format: "%.2f", gpaSummary.majorGPA),
                subtitle: "/ 4.0",
                color: .blue
            )
            SummaryCard(
                title: "Credits",
                value: "\(gpaSummary.totalCredits)",
                subtitle: "Total",
                color: .green
            )
        }
        .padding(.horizontal)
    }
    
    private var gpaTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GPA Trend")
                .font(.headline)
                .padding(.leading)

            Chart {
                ForEach(viewModel.gpaHistory(), id: \.semester) { entry in
                    LineMark(
                        x: .value("Semester", entry.semester),
                        y: .value("GPA", entry.gpa)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .foregroundStyle(Color("UTAustinOrange"))
                    .symbol(Circle())
                }
            }
            .chartYScale(domain: 0...4.0)
            .frame(height: 220)
            .padding(.horizontal)
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(color)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

