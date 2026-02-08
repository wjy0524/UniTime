//
//  GradeCalViewModel.swift
//  Quad-2025-project
//
//  ViewModel handling state management and Firebase persistence for GradeCal
//  Data syncs across all devices when user logs in with same account
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class GradeCalViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var courses: [GradeCalCourse] = []
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    let db = Firestore.firestore()
    var uid: String { Auth.auth().currentUser?.uid ?? "" }
    
    private var listener: ListenerRegistration?
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Real-time Listener
    
    /// Start listening for real-time updates (call this in .onAppear)
    func startListening() {
        // Remove existing listener first
        listener?.remove()
        
        guard !uid.isEmpty else {
            print("❌ GradeCal: User not logged in")
            return
        }
        
        isLoading = true
        
        // 🔥 Path: users/{uid}/gradecal_courses
        listener = db.collection("users")
            .document(uid)
            .collection("gradecal_courses")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ GradeCal Listener error:", error)
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.courses = []
                    self.isLoading = false
                    return
                }
                
                self.courses = documents.compactMap { try? $0.data(as: GradeCalCourse.self) }
                self.isLoading = false
            }
    }
    
    /// Stop listening
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new course
    func addCourse(name: String) -> GradeCalCourse {
        let course = GradeCalCourse(name: name)
        
        guard !uid.isEmpty else {
            print("❌ GradeCal: User not logged in")
            return course
        }
        
        do {
            try db.collection("users")
                .document(uid)
                .collection("gradecal_courses")
                .document(course.id.uuidString)
                .setData(from: course)
        } catch {
            print("❌ GradeCal Add Error:", error)
        }
        
        return course
    }
    
    /// Update an existing course
    func updateCourse(_ course: GradeCalCourse) {
        guard !uid.isEmpty else { return }
        
        var updatedCourse = course
        updatedCourse.updatedAt = Date()
        
        do {
            try db.collection("users")
                .document(uid)
                .collection("gradecal_courses")
                .document(course.id.uuidString)
                .setData(from: updatedCourse)
        } catch {
            print("❌ GradeCal Update Error:", error)
        }
    }
    
    /// Delete a course
    func deleteCourse(_ course: GradeCalCourse) {
        guard !uid.isEmpty else { return }
        
        db.collection("users")
            .document(uid)
            .collection("gradecal_courses")
            .document(course.id.uuidString)
            .delete { error in
                if let error = error {
                    print("❌ GradeCal Delete Error:", error)
                }
            }
    }
    
    /// Get a specific course by ID (from local cache)
    func getCourse(by id: UUID) -> GradeCalCourse? {
        courses.first { $0.id == id }
    }
    
    // MARK: - Grade Item Operations
    
    /// Add a grade item to a course
    func addGradeItem(_ item: GradeItem, to courseId: UUID) {
        guard var course = getCourse(by: courseId) else { return }
        course.addItem(item)
        updateCourse(course)
    }
    
    /// Update a grade item in a course
    func updateGradeItem(_ item: GradeItem, in courseId: UUID) {
        guard var course = getCourse(by: courseId) else { return }
        course.updateItem(item)
        updateCourse(course)
    }
    
    /// Delete a grade item from a course
    func deleteGradeItem(_ item: GradeItem, from courseId: UUID) {
        guard var course = getCourse(by: courseId) else { return }
        course.deleteItem(item)
        updateCourse(course)
    }
    
    // MARK: - Validation Helpers
    
    /// Validate if adding weight would exceed 100%
    func canAddWeight(_ weight: Double, to courseId: UUID, excluding itemId: UUID? = nil) -> Bool {
        guard let course = getCourse(by: courseId) else { return false }
        
        var currentTotal = course.totalWeight
        
        if let itemId = itemId,
           let item = course.gradeItems.first(where: { $0.id == itemId }) {
            currentTotal -= item.weight
        }
        
        return (currentTotal + weight) <= 100.0
    }
}
