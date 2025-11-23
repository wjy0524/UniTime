//
//  FileExportHelper.swift
//  Quad-2025-project
//
//  Created on Timetable Feature Enhancement
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
    import UIKit

    struct FileExportHelper {
        static func shareFile(
            data: Data, filename: String, contentType: UTType, onError: @escaping (String) -> Void
        ) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            do {
                try data.write(to: tempURL)

                let activityVC = UIActivityViewController(
                    activityItems: [tempURL],
                    applicationActivities: nil
                )

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                    let window = windowScene.windows.first,
                    let rootVC = window.rootViewController
                {

                    var topController = rootVC
                    while let presented = topController.presentedViewController {
                        topController = presented
                    }

                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = topController.view
                        popover.sourceRect = CGRect(
                            x: topController.view.bounds.midX,
                            y: topController.view.bounds.midY,
                            width: 0,
                            height: 0
                        )
                        popover.permittedArrowDirections = []
                    }

                    topController.present(activityVC, animated: true)
                }
            } catch {
                onError("Failed to export: \(error.localizedDescription)")
            }
        }
    }

#elseif os(macOS)
    import AppKit

    struct FileExportHelper {
        static func shareFile(
            data: Data, filename: String, contentType: UTType, onError: @escaping (String) -> Void
        ) {
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = filename
            savePanel.allowedContentTypes = [contentType]

            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try data.write(to: url)
                    } catch {
                        onError("Failed to save: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

#else

    struct FileExportHelper {
        static func shareFile(
            data: Data, filename: String, contentType: UTType, onError: @escaping (String) -> Void
        ) {
            onError("File export is not supported on this platform")
        }
    }

#endif
