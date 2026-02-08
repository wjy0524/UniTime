//
//  CourseModel.swift
//  Quad-2025-project
//
//  Created on Timetable Feature Enhancement
//

import Foundation
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

// MARK: - Course Time Model
struct CourseTime: Identifiable, Codable, Equatable {
    var id = UUID()
    var day: Int  // 0–4 (Mon–Fri)
    var startTime: Int  // minutes from midnight
    var endTime: Int  // minutes from midnight

    enum CodingKeys: String, CodingKey {
        case id, day, startTime, endTime
    }

    init(id: UUID = UUID(), day: Int, startTime: Int, endTime: Int) {
        self.id = id
        self.day = day
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - Timetable Course Model
struct TimetableCourse: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var code: String
    var instructor: String
    var location: String
    var colorHex: String  // Store color as hex string for Codable
    var times: [CourseTime]
    var isAsync: Bool  // Flag for async classes with no specific time

    enum CodingKeys: String, CodingKey {
        case id, name, code, instructor, location, colorHex, times, isAsync
    }

    init(
        id: UUID = UUID(), name: String, code: String, instructor: String, location: String,
        colorHex: String, times: [CourseTime], isAsync: Bool = false
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.instructor = instructor
        self.location = location
        self.colorHex = colorHex
        self.times = times
        self.isAsync = isAsync
    }

    // Computed property for color
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    // Helper to create with Color
    static func create(
        name: String, code: String, instructor: String, location: String, color: Color,
        times: [CourseTime], isAsync: Bool = false
    ) -> TimetableCourse {
        return TimetableCourse(
            name: name,
            code: code,
            instructor: instructor,
            location: location,
            colorHex: color.toHex(),
            times: times,
            isAsync: isAsync
        )
    }
}

// MARK: - Color Extensions
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count
        let r: Double
        let g: Double
        let b: Double
        let a: Double

        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF00_0000) >> 24) / 255.0
            g = Double((rgb & 0x00FF_0000) >> 16) / 255.0
            b = Double((rgb & 0x0000_FF00) >> 8) / 255.0
            a = Double(rgb & 0x0000_00FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String {
        #if canImport(UIKit)
            guard let components = UIColor(self).cgColor.components else {
                return "#0000FF"
            }
        #elseif canImport(AppKit)
            guard let components = NSColor(self).cgColor.components else {
                return "#0000FF"
            }
        #else
            return "#0000FF"
        #endif

        let r = components[0]
        let g = components.count > 1 ? components[1] : components[0]
        let b = components.count > 2 ? components[2] : components[0]

        return String(
            format: "#%02lX%02lX%02lX",
            lround(Double(r * 255)),
            lround(Double(g * 255)),
            lround(Double(b * 255)))
    }
}

// MARK: - CSV Import Helper
struct CSVCourseImporter {
    static func parseCourses(from csvString: String) -> [TimetableCourse] {
        var courses: [TimetableCourse] = []
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard lines.count > 1 else { return courses }

        // Expected CSV format:
        // name,code,instructor,location,colorHex,day,startTime,endTime
        // Multiple rows can have same course code for different times

        var courseDict:
            [String: (
                name: String, code: String, instructor: String, location: String, colorHex: String,
                times: [CourseTime]
            )] = [:]

        for (index, line) in lines.enumerated() {
            if index == 0 { continue }  // Skip header

            let columns = line.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }

            guard columns.count >= 8 else { continue }

            let name = columns[0]
            let code = columns[1]
            let instructor = columns[2]
            let location = columns[3]
            let colorHex = columns[4]
            let day = Int(columns[5]) ?? 0
            let startTime = Int(columns[6]) ?? 0
            let endTime = Int(columns[7]) ?? 0

            let courseTime = CourseTime(day: day, startTime: startTime, endTime: endTime)

            if var existing = courseDict[code] {
                existing.times.append(courseTime)
                courseDict[code] = existing
            } else {
                courseDict[code] = (name, code, instructor, location, colorHex, [courseTime])
            }
        }

        // Convert dictionary to array of courses
        for (_, value) in courseDict {
            let course = TimetableCourse(
                name: value.name,
                code: value.code,
                instructor: value.instructor,
                location: value.location,
                colorHex: value.colorHex,
                times: value.times
            )
            courses.append(course)
        }

        return courses
    }
}
