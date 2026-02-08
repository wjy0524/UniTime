//
//  GPAFullView.swift
//  Quad-2025-project
//

import SwiftUI
import Charts

struct GPAFullView: View {
    @EnvironmentObject var viewModel: GPAViewModel
    @State private var selectedSemester: Semester = .freshmanFall
    @State private var showingAddCourse = false
    @State private var courseToEdit: Course? = nil

    var body: some View {
        NavigationStack {
            List {
                // Overall Summary
                Section {
                    overallSummaryCard
                        .listRowInsets(EdgeInsets())
                        .padding(.bottom, 12)   // ← 추가
                }

                // Semester Picker
                Section {
                    semesterPicker
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 8)   // ← 위아래 간격

                }

                // Selected Semester Summary
                if let summary = viewModel.gpaForSemester(selectedSemester) {
                    Section {
                        semesterSummaryCards(summary)
                            .padding(.horizontal, 16)   // ← 좌우 여백 추가
                            .padding(.vertical, 10)      // ← 위아래 spacing
                            .listRowInsets(EdgeInsets())
                    }
                }

                // GPA Trend
                Section {
                    gpaTrendCard
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                        .listRowInsets(EdgeInsets())
                }

                // Courses
                Section(header: Text("Courses")) {
                    ForEach(viewModel.coursesForSemester(selectedSemester)) { course in
                        CourseCard(course: course)
                            .swipeActions {
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
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("GPA Calculator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddCourse = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(Color("UTAustinOrange"))
                    }
                }
            }
            .sheet(isPresented: $showingAddCourse) {
                AddCourseView(viewModel: viewModel)
            }
            .sheet(item: $courseToEdit) { course in
                AddCourseView(viewModel: viewModel, courseToEdit: course)
            }
        }
    }
}


////////////////////////////////////////////////////////////
// MARK: - Overall Summary Card
////////////////////////////////////////////////////////////

extension GPAFullView {
    var overallSummaryCard: some View {
        HStack(spacing: 16) {

            WhiteSummaryCard(
                title: "Overall GPA",
                value: String(format: "%.2f", viewModel.overallGPA),
                subtitle: "/ 4.0",
                valueColor: Color("UTAustinOrange")
            )

            WhiteSummaryCard(
                title: "Major GPA",
                value: String(format: "%.2f", viewModel.majorGPA),
                subtitle: "/ 4.0",
                valueColor: .blue
            )

            WhiteSummaryCard(
                title: "Credits",
                value: "\(viewModel.totalCompletedCredits)",
                subtitle: "Total",
                valueColor: .green
            )
        }
    }


}

////////////////////////////////////////////////////////////
// MARK: - Semester Picker
////////////////////////////////////////////////////////////

extension GPAFullView {
    var semesterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Semester.allCases) { sem in
                    Text(sem.rawValue)
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            selectedSemester == sem
                            ? Color("UTAustinOrange").opacity(0.2)
                            : Color(.systemGray6)
                        )
                        .foregroundColor(
                            selectedSemester == sem
                            ? Color("UTAustinOrange")
                            : .primary
                        )
                        .cornerRadius(12)
                        .onTapGesture {
                            selectedSemester = sem
                        }
                }
            }
            .padding(.horizontal, 16)   // ← ADD THIS!
        }
    }
}

////////////////////////////////////////////////////////////
// MARK: - Selected Semester Summary Cards
////////////////////////////////////////////////////////////

extension GPAFullView {
    func semesterSummaryCards(_ summary: GPASummary) -> some View {
        SemesterSummaryLargeGradientCard(
            title: selectedSemester.rawValue,
            overallGPA: summary.overallGPA,
            majorGPA: summary.majorGPA,
            credits: summary.totalCredits
        )
    }


}

////////////////////////////////////////////////////////////
// MARK: - GPA Trend
////////////////////////////////////////////////////////////

extension GPAFullView {
    var gpaTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("GPA Trend")
                .font(.headline)
                .padding(.horizontal, 4)

            Chart {
                ForEach(viewModel.gpaHistory(), id: \.semester) { entry in
                    LineMark(
                        x: .value("Semester", entry.semester),
                        y: .value("GPA", entry.gpa)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .foregroundStyle(Color("UTAustinOrange"))

                    PointMark(
                        x: .value("Semester", entry.semester),
                        y: .value("GPA", entry.gpa)
                    )
                    .foregroundStyle(Color("UTAustinOrange"))
                }
            }
            .chartYScale(domain: 0...4)
            .frame(height: 240)
            .padding(.horizontal, 6)
            .padding(.vertical, 12)

        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

}

////////////////////////////////////////////////////////////
// MARK: - Course List Section
extension GPAFullView {
    var courseListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Courses")
                .font(.headline)
                .padding(.leading, 4)

            List {
                ForEach(viewModel.coursesForSemester(selectedSemester)) { course in
                    CourseCard(course: course)
                        .listRowInsets(EdgeInsets()) // 카드가 좌우 꽉 차게
                        .padding(.vertical, 6)
                        .background(Color(.clear))
                        .swipeActions {
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
            .scrollDisabled(true)
            .frame(minHeight: 300)
            .listStyle(.plain)
        }
    }


}


