//
//  SplashView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/21/25.
//

import SwiftUI

struct SplashView: View {

    @State private var showTitle = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 14) {
                LottieView(
                    animationName: "unitime_intro",
                    loopMode: .playOnce,
                    onFinished: nil
                )
                .frame(width: 220, height: 220)

                if showTitle {
                    VStack(spacing: 6) {
                        Text("UniTime")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Color("UTAustinOrange"))

                        Text("Your AI campus assistant")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showTitle = true
            }
        }
    }
}

