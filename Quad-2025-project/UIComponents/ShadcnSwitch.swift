//
//  ShadcnSwitch.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/18/25.
//

import SwiftUI

struct ShadcnSwitch: View {
    @Binding var isOn: Bool
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: 48, height: 28)
                .animation(.easeOut(duration: 0.15), value: isOn)
            
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)
                .shadow(radius: 1.5)
                .offset(x: isOn ? 10 : -10)
                .animation(.easeOut(duration: 0.15), value: isOn)
        }
        .onTapGesture { isOn.toggle() }
    }
}
