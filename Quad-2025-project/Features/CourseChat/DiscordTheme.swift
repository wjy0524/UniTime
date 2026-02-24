//
//  DiscordTheme.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/24/26.
//

import SwiftUI

enum DiscordTheme {

    static func bg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
        ? Color(red: 0.12, green: 0.13, blue: 0.15)
        : Color(.systemGroupedBackground)
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.92) : Color(.label)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.55) : Color(.secondaryLabel)
    }

    static func inputBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
        ? Color(red: 0.16, green: 0.17, blue: 0.20)
        : Color(.secondarySystemBackground)
    }

    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
    }

    static func rowHighlight(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)
    }

    static func replyBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }
}
