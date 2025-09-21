//
//  CalendarKitView.swift
//  미국 에타
//
//  Created by Isaac Choi on 9/11/25.
//

import SwiftUI
import UIKit

struct CalendarKitView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let calendarVC = CalendarViewController()
        let nav = UINavigationController(rootViewController: calendarVC) // ✅ 감싸기
        return nav
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
