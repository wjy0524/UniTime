import SwiftUI
import Foundation

struct MonthGridView: View {
    let events: [EventModel]
    var onSelectDate: ((Date) -> Void)? = nil

    private let calendar = Calendar.current
    @State private var currentMonth: Date = Date()

    var body: some View {
        let days = makeDays(for: currentMonth)

        GeometryReader { geo in
            VStack(spacing: 8) {
                // MARK: - Month navigation
                HStack {
                    Button(action: { shiftMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(monthLabel(for: currentMonth))
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button(action: { shiftMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // MARK: - Weekday headers
                let weekdaySymbols = calendar.shortWeekdaySymbols
                HStack(spacing: 0) {
                    ForEach(weekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                    }
                }

                // MARK: - Calendar grid
                let rowHeight = (geo.size.height - 100) / 6 // taller rows
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                    spacing: 0
                ) {
                    ForEach(days.indices, id: \.self) { index in
                        if let day = days[index] {
                            Button(action: {
                                onSelectDate?(day)
                            }) {
                                ZStack {
                                    Rectangle()
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)

                                    VStack {
                                        Text("\(calendar.component(.day, from: day))")
                                            .font(.subheadline)

                                        let dayEvents = eventsFor(date: day)
                                        ForEach(Array(dayEvents.prefix(3)), id: \.id) { event in
                                            Circle()
                                                .fill(Color(event.color))
                                                .frame(width: 5, height: 5)
                                        }
                                        if dayEvents.count > 3 {
                                            Text("+\(dayEvents.count - 3)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(4)
                                }
                            }
                            .buttonStyle(PlainButtonStyle()) // prevent blue highlight
                            .frame(height: rowHeight)
                        } else {
                            Color.clear
                                .frame(height: rowHeight)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Helpers
    private func shiftMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func makeDays(for date: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        var days: [Date?] = []
        let prefix = (firstWeekday - calendar.firstWeekday + 7) % 7
        days.append(contentsOf: Array(repeating: nil, count: prefix))

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        return days
    }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func eventsFor(date: Date) -> [EventModel] {
        events.filter { ev in
            let eventDay = calendar.startOfDay(for: date)

            // 👇 Skip if this date is excluded
            if ev.excludedDates.contains(eventDay) {
                return false
            }

            let weekday = calendar.component(.weekday, from: date)
            let isRepeating = ev.repeatDays.contains(weekday)
            let startDay = calendar.startOfDay(for: ev.startDate)
            let endDay = ev.repeatEndDate.map { calendar.startOfDay(for: $0) }

            let isSingle = calendar.isDate(ev.startDate, inSameDayAs: date)
                && ev.repeatDays.isEmpty
                && (endDay == nil || eventDay <= endDay!)

            let isRepeatingEvent = isRepeating
                && eventDay >= startDay
                && (endDay == nil || eventDay <= endDay!)

            return isSingle || isRepeatingEvent
        }
    }
}

