//
//  UpcomingEventsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import SwiftUI

struct UpcomingEventsView: View {
    @ObservedObject var viewModel: EventViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Upcoming Events")
                .font(.title3.bold())
                .padding(.horizontal)

            ForEach(viewModel.events.sorted { $0.date < $1.date }) { event in
                eventRow(event)
            }
        }
    }

    func eventRow(_ event: Event) -> some View {
        HStack {
            VStack {
                Text(event.date.formatted(.dateTime.day()))
                    .font(.title.bold())
                Text(event.date.formatted(.dateTime.month(.abbreviated)))
            }
            .frame(width: 60)

            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)

                Text(event.type)
                    .font(.caption)
                    .padding(4)
                    .background(Color(hex: event.colorHex).opacity(0.2))
                    .foregroundColor(Color(hex: event.colorHex))
                    .cornerRadius(4)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
