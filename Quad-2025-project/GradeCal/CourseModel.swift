//
//  CourseModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/16/25.
//

//
//  CourseModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/16/25.
//

import Foundation
import FirebaseFirestore

struct Course: Identifiable, Codable {
    @DocumentID var id: String?   // Firestore 문서 ID
    var name: String
    var credits: Int
    var grade: String
    var isMajor: Bool
    var semester: Semester
    var semesterOrder: Int

    init(
        id: String? = nil,
        name: String,
        credits: Int,
        grade: String,
        isMajor: Bool,
        semester: Semester
    ) {
        self.id = id
        self.name = name
        self.credits = credits
        self.grade = grade
        self.isMajor = isMajor
        self.semester = semester
        self.semesterOrder = semester.order
    }

    /// 안전한 Firestore 문서 ID (nil 방지)
    var safeId: String {
        id ?? UUID().uuidString
    }
}



