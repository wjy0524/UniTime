//
//  MainTabView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        TabView {

            DashboardView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            BoardView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "rectangle.grid.2x2.fill")
                    Text("Board")
                }

            TimetableView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Timetable")
                }

            MarketplaceView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Marketplace")
                }

            DiningHomeView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Dining")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
        .environmentObject(GPAViewModel())
        .environmentObject(EventViewModel())
}
