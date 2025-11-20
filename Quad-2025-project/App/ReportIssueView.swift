//
//  ReportIssueView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//

import SwiftUI

struct ReportIssueView: View {
    @State private var message = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Describe your issue below:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $message)
                .frame(height: 200)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            
            Button("Submit") {}
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("UTAustinOrange"))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 20)
        .navigationTitle("Report a Problem")
    }
}
