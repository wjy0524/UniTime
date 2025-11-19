//
//  ShadcnCalendar.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct ShadcnCalendar: View {
    @Binding var selectedDate: Date
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 12) {
            header
            weekdays
            datesGrid
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Header (Month + Navigation)
extension ShadcnCalendar {
    var header: some View {
        HStack {
            Button(action: { moveMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
            }

            Spacer()

            Text(monthYearString(currentMonth))
                .font(.system(size: 18, weight: .semibold))

            Spacer()

            Button(action: { moveMonth(1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
            }
        }
    }
}

// MARK: - Weekday Header
extension ShadcnCalendar {
    var weekdays: some View {
        let days = ["S","M","T","W","T","F","S"]
        
        return HStack {
            ForEach(days, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Date Grid
extension ShadcnCalendar {
    var datesGrid: some View {
        let days = extractDays()
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { date in
                dateCell(date)
            }
        }
    }
}

// MARK: - Date Cell
extension ShadcnCalendar {
    func dateCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        
        return VStack {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            isSelected ? Color.accentColor :
                                (isToday ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                )
                .foregroundColor(
                    isSelected ? .white :
                        (isCurrentMonth ? .primary : .secondary.opacity(0.4))
                )
                .onTapGesture {
                    selectedDate = date
                    // Always show selected month
                    currentMonth = date
                }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Helper Functions
extension ShadcnCalendar {
    func moveMonth(_ value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    func extractDays() -> [Date] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year,.month], from: currentMonth))!
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        
        var dates: [Date] = []
        
        for dayOffset in -firstWeekday..<42-firstWeekday {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) {
                dates.append(date)
            }
        }
        
        return dates
    }

    func monthYearString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }
}
