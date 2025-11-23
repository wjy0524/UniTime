//
//  CalendarView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//
//  CalendarView.swift
//

import SwiftUI

struct CalendarView: View {
    @StateObject var viewModel = EventViewModel()
    @State private var selectedDate = Date()

    @State private var showAddEvent = false
    @State private var showShareEvent = false
    @State private var showEditEvent = false
    @State private var eventToShare: Event?
    @State private var eventToEdit: Event?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // 🔥 1) 월간 달력 (커스텀)
                    CalendarMonthView(
                        viewModel: viewModel,
                        selectedDate: $selectedDate
                    )
                    .padding(.top)

                    // 🔥 2) 해당 날짜 이벤트 리스트
                    dayEventList

                    // 🔥 3) All Events (Past & Future)
                    AllEventsView(
                        viewModel: viewModel,
                        onEdit: { event in
                            eventToEdit = event
                            showEditEvent = true
                        },
                        onShare: { event in
                            eventToShare = event
                            showShareEvent = true
                        }
                    )
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
            .sheet(isPresented: $showEditEvent) {
                if let event = eventToEdit {
                    EditEventView(event: event, viewModel: viewModel)
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

    // MARK: - 이벤트 리스트 UI (선택된 날짜)
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)

                        Text(event.date.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if !event.location.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text(event.location)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Menu {
                        Button {
                            eventToEdit = event
                            showEditEvent = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button {
                            eventToShare = event
                            showShareEvent = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive) {
                            viewModel.deleteEvent(event)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }

    func formattedDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - All Events View (Shows Past & Future)
struct AllEventsView: View {
    @ObservedObject var viewModel: EventViewModel
    var onEdit: (Event) -> Void
    var onShare: (Event) -> Void

    @State private var showPastEvents = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header with toggle
            HStack {
                Text("All Events")
                    .font(.title3.bold())

                Spacer()

                Button {
                    withAnimation {
                        showPastEvents.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showPastEvents ? "eye.fill" : "eye.slash.fill")
                        Text(showPastEvents ? "Hide Past" : "Show Past")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Events grouped by upcoming and past
            if !upcomingEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.horizontal)

                    ForEach(upcomingEvents) { event in
                        eventRow(event, isPast: false)
                    }
                }
            }

            if showPastEvents && !pastEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Past Events")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ForEach(pastEvents) { event in
                        eventRow(event, isPast: true)
                    }
                }
            }

            if viewModel.events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("No events yet")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Tap + to add your first event")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }

    var upcomingEvents: [Event] {
        viewModel.events
            .filter { $0.date >= Date() }
            .sorted { $0.date < $1.date }
    }

    var pastEvents: [Event] {
        viewModel.events
            .filter { $0.date < Date() }
            .sorted { $0.date > $1.date }  // Most recent first
    }

    func eventRow(_ event: Event, isPast: Bool) -> some View {
        HStack(spacing: 12) {
            // Date box
            VStack(spacing: 2) {
                Text(event.date.formatted(.dateTime.day()))
                    .font(.title2.bold())
                    .foregroundColor(isPast ? .gray : .primary)

                Text(event.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(isPast ? .gray : .secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(isPast ? Color.gray.opacity(0.1) : Color.orange.opacity(0.1))
            .cornerRadius(8)

            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(isPast ? .gray : .primary)

                HStack(spacing: 8) {
                    Text(event.type)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Color(hexStr: event.colorHex)?.opacity(0.2) ?? Color.orange.opacity(0.2)
                        )
                        .foregroundColor(Color(hexStr: event.colorHex) ?? .orange)
                        .cornerRadius(4)

                    Text(event.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !event.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(event.location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions menu
            Menu {
                Button {
                    onEdit(event)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    onShare(event)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button(role: .destructive) {
                    viewModel.deleteEvent(event)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .opacity(isPast ? 0.7 : 1.0)
    }
}
