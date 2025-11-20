//
//  CalendarView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//
//
//  CalendarView.swift
//

import SwiftUI

struct CalendarView: View {
    @StateObject var viewModel = EventViewModel()
    @State private var selectedDate = Date()

    @State private var showAddEvent = false
    @State private var showShareEvent = false
    @State private var eventToShare: Event?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // 🔥 1) 월간 달력 (커스텀)
                    CalendarMonthView(viewModel: viewModel,
                                      selectedDate: $selectedDate)
                        .padding(.top)

                    // 🔥 2) 해당 날짜 이벤트 리스트
                    dayEventList

                    // 🔥 3) Upcoming Events
                    UpcomingEventsView(viewModel: viewModel)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("UTAustinOrange"))
                    }
                }
            }
            .onAppear {
                viewModel.startListening()
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView { newEvent in
                    Task {
                        await viewModel.addEvent(newEvent)
                    }
                }
            }
            .sheet(isPresented: $showShareEvent) {
                if let event = eventToShare {
                    ShareEventView(event: event) { uid in
                        Task { await viewModel.shareEvent(event, to: uid) }
                    }
                }
            }
        }
    }

    // MARK: - 이벤트 리스트 UI
    var dayEventList: some View {
        VStack(alignment: .leading, spacing: 12) {

            let eventsToday = viewModel.events(on: selectedDate)

            if !eventsToday.isEmpty {
                Text("Events on \(formattedDay(selectedDate))")
                    .font(.headline)
                    .padding(.horizontal)
            }

            ForEach(eventsToday) { event in
                HStack {
                    VStack(alignment: .leading) {
                        Text(event.title)
                            .font(.headline)

                        Text(event.date.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Menu {
                        Button("Share") {
                            eventToShare = event
                            showShareEvent = true
                        }
                        Button("Delete", role: .destructive) {
                            viewModel.deleteEvent(event)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    func formattedDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
