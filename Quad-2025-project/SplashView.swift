//
//  SplashView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/21/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var fadeOut = false
    @State private var scaleUp = false
    @State private var animateGradient = false

    var body: some View {
        if isActive {
            AuthGateView()
        } else {
            ZStack {
                // 🔹 애니메이팅 그라데이션 배경
                LinearGradient(
                    gradient: Gradient(colors: [
                        animateGradient ? Color("UTAustinOrange") : .orange,
                        animateGradient ? .white : .yellow
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGradient)
                .opacity(fadeOut ? 0 : 1)

                // 🔹 로고 (확대 + 페이드 아웃)
                Image("UniTimeLogo") // Assets.xcassets 안에 넣어둔 로고 이미지
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .scaleEffect(scaleUp ? 1.2 : 1.0)
                    .opacity(fadeOut ? 0 : 1)
                    .animation(.easeInOut(duration: 1.5), value: fadeOut)
                    .animation(.easeInOut(duration: 1.5), value: scaleUp)
            }
            .onAppear {
                animateGradient.toggle()

                // 1.2초 뒤 로고 확대 시작
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation {
                        scaleUp = true
                    }
                }

                // 1.5초 뒤 로고 & 배경 페이드 아웃
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        fadeOut = true
                    }
                }

                // 2.5초 뒤 메인 화면으로 전환
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    isActive = true
                }
            }
        }
    }
}

struct MainView: View {
    var body: some View {
        NavigationView {
            Text("🎓 UniTime Home")
                .font(.largeTitle)
        }
    }
}
