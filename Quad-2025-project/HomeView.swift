//
//  HomeView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/8/25.
//

// HomeView.swift
import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to UniTime")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()


                // 🔹 Dining 메뉴 버튼
                NavigationLink(destination: DiningHallSelectionView()) {
                    Text("🍽 UT Dining Menu")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // 🔹 GPA 계산기 버튼
                NavigationLink(destination: GPAFullView()) {
                    Text("🎓 GPA Calculator")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                NavigationLink(destination: CalendarKitView()) {
                    Text("📅 My Calendar")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                NavigationLink(destination: ShareRequestsView()) {
                    Text("🤝 Share Requests")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}


