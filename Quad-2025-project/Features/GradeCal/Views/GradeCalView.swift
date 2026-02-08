//
//  GradeCalView.swift
//  Quad-2025-project
//
//  Main view for Grade Calculator - displays list of courses
//

import SwiftUI

struct GradeCalView: View {
    @StateObject private var viewModel = GradeCalViewModel()
    @State private var showingAddCourse = false
    @State private var courseToDelete: GradeCalCourse?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.courses.isEmpty {
                    emptyStateView
                } else {
                    courseListView
                }
            }
            .navigationTitle("Grade Calculator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddCourse = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(Color("UTAustinOrange"))
                    }
                }
            }
            .onAppear {
                viewModel.startListening()
            }
            .sheet(isPresented: $showingAddCourse) {
                AddGradeCalCourseView(viewModel: viewModel)
            }
            .alert("Delete Course", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let course = courseToDelete {
                        viewModel.deleteCourse(course)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this course? All grades will be lost.")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color("UTAustinOrange").opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Text("A")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color("UTAustinOrange"))
            }
            
            Text("No Courses Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add a course to start tracking your grades")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingAddCourse = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Course")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color("UTAustinOrange"))
                .cornerRadius(12)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Course List
    
    private var courseListView: some View {
        List {
            ForEach(viewModel.courses) { course in
                NavigationLink(destination: CourseDetailView(courseId: course.id, viewModel: viewModel)) {
                    CourseRowView(course: course)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        courseToDelete = course
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Course Row View

struct CourseRowView: View {
    let course: GradeCalCourse
    
    var body: some View {
        HStack(spacing: 16) {
            // Grade Circle
            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Text(course.gradeItems.isEmpty ? "-" : course.letterGrade)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(gradeColor)
            }
            
            // Course Info
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("\(course.gradeItems.count) items", systemImage: "list.bullet")
                    
                    if !course.gradeItems.isEmpty {
                        Text(String(format: "%.1f%%", course.calculatedGrade))
                            .fontWeight(.medium)
                            .foregroundColor(gradeColor)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Weight indicator
            if !course.gradeItems.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", course.totalWeight))
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("weight")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var gradeColor: Color {
        let grade = course.calculatedGrade
        if course.gradeItems.isEmpty { return .gray }
        switch grade {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }
}

#Preview {
    GradeCalView()
}
