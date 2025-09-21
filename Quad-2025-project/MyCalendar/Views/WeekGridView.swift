import SwiftUI

struct WeekGridView: View {
    let events: [EventModel]
    private let calendar = Calendar.current
    private let days = Array(0..<7) // offsets

    var body: some View {
        let startOfWeek = calendar.startOfWeek(for: Date())
        let today = calendar.startOfDay(for: Date())

        VStack {
            Text("Week View")
                .font(.title2)
                .bold()
                .padding()

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(days, id: \.self) { offset in
                            let dayDate = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
                            VStack(alignment: .leading, spacing: 8) {
                                Text(shortLabel(for: dayDate))
                                    .font(.headline)

                                ForEach(eventsFor(date: dayDate)) { event in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Circle()
                                                .fill(Color(event.color))
                                                .frame(width: 8, height: 8)
                                            Text(event.title)
                                                .font(.subheadline)
                                        }
                                        Text(timeRange(for: event))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        if let location = event.location {
                                            Text(location)
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .frame(width: 140, height: 500)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                            .id(offset) // 👈 important for ScrollViewReader
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    // Find today's index inside the week
                    if let todayIndex = days.first(where: {
                        calendar.isDate(calendar.date(byAdding: .day, value: $0, to: startOfWeek)!, inSameDayAs: today)
                    }) {
                        withAnimation {
                            proxy.scrollTo(todayIndex, anchor: .center) // 👈 Center today
                        }
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - Helpers
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


    private func shortLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E\nd MMM"
        return formatter.string(from: date)
    }

    private func timeRange(for event: EventModel) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
}

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? date
    }
}

