//
//  Color+Hex.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import SwiftUI

extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // "#" 제거
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        // 6자리 hex인지 검사
        guard hexString.count == 6,
              let intCode = Int(hexString, radix: 16) else {
            return nil
        }

        let red = Double((intCode >> 16) & 0xFF) / 255.0
        let green = Double((intCode >> 8) & 0xFF) / 255.0
        let blue = Double(intCode & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
