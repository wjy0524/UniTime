//
//  CourseDetailView.swift
//  Quad-2025-project
//
//  Detailed view of a course with grade items organized by category
//

import SwiftUI

struct CourseDetailView: View {
    let courseId: UUID
    @ObservedObject var viewModel: GradeCalViewModel
    
    @State private var showingAddItem = false
    @State private var selectedCategory: GradeCategory = .assignments
    @State private var itemToEdit: GradeItem?
    @State private var itemToDelete: GradeItem?
    @State private var showDeleteAlert = false
    
    private var course: GradeCalCourse? {
        viewModel.getCourse(by: courseId)
    }
    
    var body: some View {
        ZStack {  // 🔥 Changed from Group to ZStack
            if let course = course {
                ScrollView {
                    VStack(spacing: 20) {
                        // Grade Summary Card
                        gradeSummaryCard(course)
                        
                        // Weight Warning (if exceeded)
                        if !course.isWeightValid {
                            weightWarningBanner
                        }
                        
                        // Category Sections
                        ForEach(GradeCategory.allCases) { category in
                            categorySection(category, course: course)
                        }
                        
                        // 🔥 Add bottom padding for floating button
                        Spacer().frame(height: 80)
                    }
                    .padding()
                }
                .navigationTitle(course.name)
                .navigationBarTitleDisplayMode(.large)
                .sheet(isPresented: $showingAddItem) {
                    AddGradeItemView(
                        viewModel: viewModel,
                        courseId: courseId,
                        preselectedCategory: selectedCategory
                    )
                }
                .sheet(item: $itemToEdit) { item in
                    AddGradeItemView(
                        viewModel: viewModel,
                        courseId: courseId,
                        itemToEdit: item
                    )
                }
                .alert("Delete Item", isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let item = itemToDelete {
                            viewModel.deleteGradeItem(item, from: courseId)
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this grade item?")
                }
                
                // 🔥 NEW: Floating AI Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        GradeCalAIButton(course: course)
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
                
            } else {
                Text("Course not found")
                    .foregroundColor(.secondary)
            }
        }
        
        .onAppear {
                NotificationCenter.default.post(name: .hideGlobalChat, object: nil)
            }
            .onDisappear {
                NotificationCenter.default.post(name: .showGlobalChat, object: nil)
            }
    }
    
    // MARK: - Grade Summary Card
    
    private func gradeSummaryCard(_ course: GradeCalCourse) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Letter Grade
                ZStack {
                    Circle()
                        .fill(gradeColor(for: course).opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Text(course.gradeItems.isEmpty ? "-" : course.letterGrade)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(gradeColor(for: course))
                }
                
                // Grade Details
                VStack(alignment: .leading, spacing: 8) {
                    if course.gradeItems.isEmpty {
                        Text("No grades yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    } else {
                        Text(String(format: "%.2f%%", course.calculatedGrade))
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Current Grade")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Weight Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Weight Used")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%% / 100%%", course.totalWeight))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(course.isWeightValid ? Color("UTAustinOrange") : Color.red)
                            .frame(width: geometry.size.width * min(course.totalWeight / 100, 1.0), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Weight Warning
    
    private var weightWarningBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text("Total weight exceeds 100%")
                .font(.subheadline)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // MARK: - Category Section
    
    private func categorySection(_ category: GradeCategory, course: GradeCalCourse) -> some View {
        let items = course.items(for: category)
        let categoryWeight = course.totalWeight(for: category)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(categoryColor(category))
                
                Text(category.rawValue)
                    .font(.headline)
                
                Spacer()
                
                if !items.isEmpty {
                    Text(String(format: "%.1f%% weight", categoryWeight))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    selectedCategory = category
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color("UTAustinOrange"))
                }
            }
            
            if items.isEmpty {
                Text("No \(category.rawValue.lowercased()) yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(items) { item in
                    GradeItemCard(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            itemToEdit = item
                        }
                        .contextMenu {
                            Button {
                                itemToEdit = item
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                itemToDelete = item
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
    
    // MARK: - Helpers
    
    private func gradeColor(for course: GradeCalCourse) -> Color {
        if course.gradeItems.isEmpty { return .gray }
        let grade = course.calculatedGrade
        switch grade {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }
    
    private func categoryColor(_ category: GradeCategory) -> Color {
        switch category {
        case .assignments: return .blue
        case .quizzes: return .purple
        case .exams: return .red
        case .other: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(courseId: UUID(), viewModel: GradeCalViewModel())
    }
}
