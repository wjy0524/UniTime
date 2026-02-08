//
//  AddGradeCalCourseView.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 1/27/26.
//

import SwiftUI

struct AddGradeCalCourseView: View {
    @ObservedObject var viewModel: GradeCalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var courseName = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color("UTAustinOrange").opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color("UTAustinOrange"))
                }
                .padding(.top, 20)
                
                // Title
                Text("Add New Course")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Course Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., CS 429 Computer Architecture", text: $courseName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Create Button
                Button {
                    createCourse()
                } label: {
                    Text("Create Course")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(courseName.isEmpty ? Color.gray : Color("UTAustinOrange"))
                        )
                }
                .disabled(courseName.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createCourse() {
        _ = viewModel.addCourse(name: courseName.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
    }
}

#Preview {
    AddGradeCalCourseView(viewModel: GradeCalViewModel())
}
