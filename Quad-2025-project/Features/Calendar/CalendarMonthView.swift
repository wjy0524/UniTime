//
//  CalendarMonthView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.


import SwiftUI

struct CalendarMonthView: View {
    @ObservedObject var viewModel: EventViewModel
    @Binding var selectedDate: Date

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            dayOfWeekHeader
            calendarGrid
        }
    }
}

extension CalendarMonthView {
    // MARK: - Header
    var monthHeader: some View {
        HStack {
            Button { changeMonth(-1) } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(formattedMonth(selectedDate))
                .font(.title2.bold())

            Spacer()

            Button { changeMonth(1) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }

    func formattedMonth(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date)
    }

    func changeMonth(_ offset: Int) {
        selectedDate = calendar.date(byAdding: .month, value: offset, to: selectedDate) ?? selectedDate
    }
}

extension CalendarMonthView {
    // MARK: - Weekday Row
    var dayOfWeekHeader: some View {
        HStack {
            ForEach(["Sun","Mon","Tue","Wed","Thu","Fri","Sat"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }
}

extension CalendarMonthView {
    // MARK: - Grid
    var calendarGrid: some View {
        let days = generateDays(for: selectedDate)

        return VStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { col in
                        let day = days[row * 7 + col]
                        dayCell(day)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    struct DayInfo: Identifiable {
        let id = UUID()
        let date: Date?
        let isToday: Bool
    }

    func generateDays(for date: Date) -> [DayInfo] {
        var days: [DayInfo] = []
        let month = calendar.dateInterval(of: .month, for: date)!
        let first = month.start
        let weekday = calendar.component(.weekday, from: first)

        // 빈칸
        for _ in 1..<weekday {
            days.append(DayInfo(date: nil, isToday: false))
        }

        // 날짜 채우기
        for d in 0..<calendar.range(of: .day, in: .month, for: date)!.count {
            let date = calendar.date(byAdding: .day, value: d, to: first)!
            days.append(DayInfo(date: date, isToday: calendar.isDateInToday(date)))
        }

        // 총 42칸
        while days.count < 42 {
            days.append(DayInfo(date: nil, isToday: false))
        }

        return days
    }
}

extension CalendarMonthView {
    // MARK: - Cell View
    @ViewBuilder
    func dayCell(_ day: DayInfo) -> some View {
        if let date = day.date {
            let eventsToday = viewModel.events(on: date)
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.footnote)
                    .foregroundColor(.primary)

                // 첫 번째 이벤트 미리보기
                ForEach(eventsToday.prefix(1)) { event in
                    Text(event.title)
                        .font(.caption2)
                        .padding(3)
                        .background(Color(hex: event.colorHex).opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(Color(hex: event.colorHex))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
            .padding(4)
            .background(
                isSelected
                    ? Color("UTAustinOrange").opacity(0.15)
                    : Color(.systemBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                        ? Color("UTAustinOrange")
                        : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .onTapGesture {
                selectedDate = date
            }

        } else {
            Rectangle()
                .fill(Color.clear)
                .frame(maxWidth: .infinity, minHeight: 60)
        }
    }
}
