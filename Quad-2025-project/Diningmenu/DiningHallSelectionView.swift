//
//  DiningHallSelectionView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/15/25.
//

// DiningHallSelectionView.swift
import SwiftUI

struct DiningHallSelectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Select a Dining Hall")
                .font(.title2)
                .padding()

            NavigationLink(destination: DiningMenuView(hall: "J2_JCL")) {
                Text("🍽 J2 / JCL")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            NavigationLink(destination: DiningMenuView(hall: "Kins")) {
                Text("🍽 Kins")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .navigationTitle("UT Dining")
    }
}

