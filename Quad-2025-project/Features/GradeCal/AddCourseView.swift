//
//  AddCourseView.swift
//  Quad-2025-project
//

import SwiftUI

struct AddCourseView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: GPAViewModel
    
    @State private var name: String
    @State private var credits: String
    @State private var grade: String
    @State private var isMajor: Bool
    @State private var semester: Semester
    
    @State private var showDeleteAlert = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var courseToEdit: Course?
    
    init(viewModel: GPAViewModel, courseToEdit: Course? = nil) {
        self.viewModel = viewModel
        if let edit = courseToEdit {
            _name = State(initialValue: edit.name)
            _credits = State(initialValue: String(edit.credits))
            _grade = State(initialValue: edit.grade)
            _isMajor = State(initialValue: edit.isMajor)
            _semester = State(initialValue: edit.semester)
        } else {
            _name = State(initialValue: "")
            _credits = State(initialValue: "")
            _grade = State(initialValue: "A")
            _isMajor = State(initialValue: false)
            _semester = State(initialValue: .freshmanFall)
        }
        self.courseToEdit = courseToEdit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Course Info")) {
                    TextField("Course Name", text: $name)
                    
                    TextField("Credits", text: $credits)
                        .keyboardType(.numberPad)
                    
                    Picker("Grade", selection: $grade) {
                        ForEach(["A","A-","B+","B","B-","C+","C","C-","D","F"], id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Toggle("Major Course", isOn: $isMajor)
                    
                    Picker("Semester", selection: $semester) {
                        ForEach(Semester.allCases) { sem in
                            Text(sem.rawValue).tag(sem)
                        }
                    }
                }
                
                if let _ = courseToEdit {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Course")
                        }
                    }
                }
            }
            .navigationTitle(courseToEdit == nil ? "Add Course" : "Edit Course")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let c = Int(credits) {
                            let newCourse = Course(
                                id: courseToEdit?.id, // ✅ Firestore에 safeId로 처리됨
                                name: name,
                                credits: c,
                                grade: grade,
                                isMajor: isMajor,
                                semester: semester
                            )
                            if courseToEdit != nil {
                                viewModel.updateCourse(newCourse)
                            } else {
                                viewModel.addCourse(newCourse)
                            }

                            // ✅ Haptic
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)

                            // ✅ Toast
                            showToastMessage("Course saved ✅")

                            // ✅ Toast 잠깐 보여주고 dismiss
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                            }
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Are you sure you want to delete this course?",
                   isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let editCourse = courseToEdit {
                        viewModel.deleteCourse(editCourse)
                        
                        // ✅ Haptic
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                        
                        // ✅ Toast
                        showToastMessage("Course deleted 🗑️")
                        
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            // 🔹 에타 스타일 Toast Overlay
            .overlay(
                Group {
                    if showToast {
                        Text(toastMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                            .padding(.top, 60)
                    }
                },
                alignment: .top
            )
        }
    }
    
    // MARK: - Toast Helper
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}








