//
//  AIChatEmptyView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 12/31/25.
//

import SwiftUI

struct AIChatEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(.gray)

            Text("Ask me anything about UT Austin")
                .font(.headline)

            Text("""
Courses, majors, transfers, careers,
clubs, campus life — all UT-specific.
""")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
