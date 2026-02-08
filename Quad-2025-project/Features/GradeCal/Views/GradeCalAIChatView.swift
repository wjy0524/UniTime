//
//  GradeCalAIChatView.swift
//  Quad-2025-project
//
//  Chat UI for GradeCal predictions (replaces global chatbot in GradeCal)
//

import SwiftUI

struct GradeCalAIChatView: View {
    @StateObject private var viewModel: GradeCalAIViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    
    let course: GradeCalCourse
    
    init(course: GradeCalCourse) {
        self.course = course
        _viewModel = StateObject(wrappedValue: GradeCalAIViewModel(course: course))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Coverage Warning Banner
                if let warning = viewModel.coverageWarning {
                    coverageWarningBanner(warning)
                }
                
                // Course Summary
                courseSummaryHeader
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Calculating scenarios...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Quick Actions
                quickActionButtons
                
                // Input
                inputBar
            }
            .navigationTitle("Grade Predictor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Coverage Warning
    
    private func coverageWarningBanner(_ warning: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(warning)
                .font(.caption)
            
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
    }
    
    // MARK: - Course Summary
    
    private var courseSummaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                
                Text("Current: \(course.letterGrade) (\(String(format: "%.1f", course.calculatedGrade))%)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.0f", course.gradedWeight))% graded")  // 🔥 Changed
                    .font(.caption)
                
                Text("\(String(format: "%.0f", course.ungradedWeight))% ungraded")  // 🔥 Changed
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Quick Actions
    
    private var quickActionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                QuickActionChip(title: "Get an A (93%+)") {
                    Task { await viewModel.askForTarget(93) }
                }
                
                QuickActionChip(title: "Get an A- (90%+)") {
                    Task { await viewModel.askForTarget(90) }
                }
                
                QuickActionChip(title: "Get a B+ (87%+)") {
                    Task { await viewModel.askForTarget(87) }
                }
                
                QuickActionChip(title: "Get a B (84%+)") {
                    Task { await viewModel.askForTarget(84) }
                }
                
                QuickActionChip(title: "Best possible?") {
                    Task { await viewModel.sendMessage("What's the best grade I can realistically achieve?") }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about your grade...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
            
            Button {
                let text = inputText
                inputText = ""
                Task { await viewModel.sendMessage(text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.isEmpty ? .gray : Color("UTAustinOrange"))
            }
            .disabled(inputText.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Supporting Views

struct GradeCalChatBubble: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }
            
            Text(message.text)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isFromUser ? Color("UTAustinOrange") : Color(.systemGray5))
                )
                .foregroundColor(message.isFromUser ? .white : .primary)
            
            if !message.isFromUser { Spacer() }
        }
    }
}

struct QuickActionChip: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color("UTAustinOrange").opacity(0.1))
                )
                .foregroundColor(Color("UTAustinOrange"))
        }
    }
}
