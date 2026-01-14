//
//  SplashView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/21/25.
//

import SwiftUI

struct SplashView: View {
    @State private var showMain = false
    @State private var showTitle = false

    var body: some View {
        if showMain {
            AuthGateView()
        } else {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 12) {

                    // Lottie Animation
                    LottieView(
                        animationName: "unitime_intro",
                        loopMode: .playOnce
                    ) {
                        // 로띠 끝 → 타이틀 보여주고 → 메인 전환
                        withAnimation(.easeOut(duration: 0.4)) {
                            showTitle = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showMain = true
                            }
                        }
                    }
                    .frame(width: 220, height: 220)

                    // App Title
                    if showTitle {
                        Text("UniTime")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Color("UTAustinOrange"))
                            .transition(
                                .opacity.combined(with: .move(edge: .bottom))
                            )
                    }
                }
            }
        }
    }
}

