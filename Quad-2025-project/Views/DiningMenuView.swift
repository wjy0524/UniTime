//
//  DiningMenuView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/15/25.
//

import SwiftUI

struct DiningMenuView: View {
    let hall: String
    @StateObject private var viewModel = DiningViewModel()

    var body: some View {
        VStack {
            if let menu = viewModel.menu {
                List {
                    if let breakfast = menu.breakfast {
                        Section(header: Text("🍳 Breakfast")) {
                            ForEach(breakfast, id: \.self) { item in
                                Text(item)
                            }
                        }
                    }

                    if let lunch = menu.lunch {
                        Section(header: Text("🥗 Lunch")) {
                            ForEach(lunch, id: \.self) { item in
                                Text(item)
                            }
                        }
                    }

                    if let dinner = menu.dinner {
                        Section(header: Text("🍽 Dinner")) {
                            ForEach(dinner, id: \.self) { item in
                                Text(item)
                            }
                        }
                    }
                }
            } else if let error = viewModel.errorMessage {
                Text("⚠️ \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ProgressView("Loading menu…")
                    .padding()
            }
        }
        .navigationTitle(hall)
        .onAppear {
            viewModel.fetchMenu(hall: hall)
        }
    }
}
