//
//  AboutAppView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import SwiftUI

struct AboutAppView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quad App")
                .font(.largeTitle.bold())
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Quad is a student platform for scheduling, GPA tracking, dining, and community features built for UT Austin.")
                .font(.body)
                .padding(.top, 6)
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}
