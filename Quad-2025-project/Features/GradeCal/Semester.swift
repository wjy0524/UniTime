//
//  Semester.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/17/25.
//

import Foundation

enum Semester: String, Codable, CaseIterable, Identifiable {
    case freshmanFall = "Freshman Fall"
    case freshmanSpring = "Freshman Spring"
    case sophomoreFall = "Sophomore Fall"
    case sophomoreSpring = "Sophomore Spring"
    case juniorFall = "Junior Fall"
    case juniorSpring = "Junior Spring"
    case seniorFall = "Senior Fall"
    case seniorSpring = "Senior Spring"

    var id: String { rawValue }
    
    /// 학기 정렬 순서
    var order: Int {
        switch self {
        case .freshmanFall: return 1
        case .freshmanSpring: return 2
        case .sophomoreFall: return 3
        case .sophomoreSpring: return 4
        case .juniorFall: return 5
        case .juniorSpring: return 6
        case .seniorFall: return 7
        case .seniorSpring: return 8
        }
    }
}

