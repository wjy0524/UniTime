//
//  WeekdayPickerView.swift
//  미국 에타
//
//  Created by Isaac Choi on 9/11/25.
//

import Foundation
import SwiftUI

import SwiftUI

struct WeekdayPickerView: View {
    @Binding var selectedDays: Set<Int>
    var currentWeekday: Int? = nil   // Sunday=1, Monday=2, ...

    private let weekdays = Calendar.current.shortWeekdaySymbols // ["Sun","Mon",...]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...7, id: \.self) { day in
                let label = weekdays[day - 1]
                let isSelected = selectedDays.contains(day)
                let isLocked = (day == currentWeekday)

                Button {
                    // prevent deselecting locked day
                    if isLocked { return }

                    if isSelected {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                } label: {
                    Text(label.prefix(2)) // Su, Mo, Tu...
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(isSelected ? .blue : .gray.opacity(0.2))
                        )
                        .foregroundColor(isSelected ? .white : .primary)
                        .overlay(
                            // 🔒 show border for locked current day
                            Circle().stroke(isLocked ? Color.red : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isLocked) // can't tap today
            }
        }
    }
}
