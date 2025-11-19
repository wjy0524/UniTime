//
//  ShadcnSelect.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct ShadcnSelect<Option: Hashable>: View {
    @Binding var selection: Option?
    let options: [Option]
    let placeholder: String
    let label: (Option) -> String

    @State private var isOpen = false
    @Namespace private var animation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isOpen.toggle()
                }
            } label: {
                HStack {
                    Text(selection.map { label($0) } ?? placeholder)
                        .foregroundColor(selection == nil ? .gray : .primary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3))
                )
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                                selection = option
                                isOpen = false
                            }
                        } label: {
                            HStack {
                                Text(label(option))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(
                                Rectangle()
                                    .fill(Color.primary.opacity(0.05))
                                    .opacity(selection == option ? 1 : 0)
                            )
                        }
                        .buttonStyle(.plain)

                        if option != options.last {
                            Divider()
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
                )
                .padding(.top, 4)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isOpen)
        .overlay(
            Group {
                if isOpen {
                    Color.black.opacity(0.001) // invisible tap catcher
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                isOpen = false
                            }
                        }
                }
            }
        )
    }
}
