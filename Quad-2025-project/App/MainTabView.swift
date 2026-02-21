//
//  MainTabView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                TabView {
                    DashboardView()
                        .environmentObject(authManager)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                    
                    NavigationStack {
                            CourseChatListView()
                        }
                        .tabItem {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Chats")
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
                        .badge(chatViewModel.getTotalUnreadCount())
                        .onAppear {
                            chatViewModel.startListeningToConversations()
                        }
                    NavigationStack {
                        DiningHomeView()
                            .environmentObject(authManager)
                    }
                    .tabItem {
                        Image(systemName: "fork.knife")
                        Text("Dining")
                    }
                }
                
                FloatingAIChatButton()
                    .padding(.trailing, 0)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 0) //채팅창 올리고 내리고
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
        .environmentObject(GPAViewModel())
        .environmentObject(EventViewModel())
}
