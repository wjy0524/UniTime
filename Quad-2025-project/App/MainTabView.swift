//
//  MainTabView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            BoardView()
                .tabItem {
                    Image(systemName: "rectangle.grid.2x2.fill")
                    Text("Board")
                }

            TimetableView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Timetable")
                }

            GPAFullView()
                .tabItem {
                    Image(systemName: "graduationcap.fill")
                    Text("GPA")
                }

            DiningHomeView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Dining")
                }
        }
    }
}
