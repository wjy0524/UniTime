//
//  EventModel.swift
//  미국 에타
//
//  Created by Isaac Choi on 9/11/25.
//
import Foundation
import UIKit

struct EventModel: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let location: String?
    let startDate: Date
    let endDate: Date
    let colorHex: String
    var repeatDays: Set<Int>   // use Set for safety
    var reminderMinutesBefore: Int?
    var repeatEndDate: Date?
    var excludedDates: [Date]

    init(
        id: UUID = UUID(),
        title: String,
        location: String?,
        startDate: Date,
        endDate: Date,
        color: UIColor,
        repeatDays: Set<Int> = [],
        reminderMinutesBefore: Int? = nil,
        repeatEndDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.colorHex = color.hexString
        self.repeatDays = repeatDays   
        self.reminderMinutesBefore = reminderMinutesBefore
        self.repeatEndDate = repeatEndDate
        self.excludedDates = []
    }

    var color: UIColor {
        UIColor(hex: colorHex) ?? .blue
    }
}
