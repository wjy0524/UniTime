//
//  EventShareRequestsView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/25/26.
//

import SwiftUI

struct EventShareRequestsView: View {
    @StateObject private var vm = EventShareRequestViewModel()

    var body: some View {
        List {
            if vm.requests.isEmpty {
                Text("No event requests")
                    .foregroundColor(.secondary)
            }

            ForEach(vm.requests) { req in
                EventShareRequestRow(
                    req: req,
                    vm: vm
                )
            }
        }
        .navigationTitle("Event Requests")
        .onAppear {
            vm.startListening()
        }
    }
}
