//
//  BoardView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct BoardView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Board")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Text("게시판 기능은 곧 추가될 예정입니다!")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Board")
        }
    }
}

#Preview {
    BoardView()
}
