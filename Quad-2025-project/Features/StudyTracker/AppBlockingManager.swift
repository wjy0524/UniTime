//
//  AppBlockingManager.swift
//  Quad-2025-project
//
//  Manages app blocking using Screen Time API (Family Controls)
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UIKit

@available(iOS 16.0, *)
class AppBlockingManager: ObservableObject {

    static let shared = AppBlockingManager()

    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    enum AuthorizationStatus {
        case notDetermined
        case approved
        case denied
    }

    func checkAuthorizationStatus() {
        switch center.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
            isAuthorized = false
        case .approved:
            authorizationStatus = .approved
            isAuthorized = true
        case .denied:
            authorizationStatus = .denied
            isAuthorized = false
        @unknown default:
            authorizationStatus = .notDetermined
            isAuthorized = false
        }
    }

    func requestAuthorization() async throws {
        do {
            try await center.requestAuthorization(for: .individual)
            DispatchQueue.main.async {
                self.checkAuthorizationStatus()
            }
        } catch {
            print("Failed to request authorization: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - App Blocking

    func blockApps(tokens: FamilyActivitySelection) {
        guard isAuthorized else {
            print("Not authorized to block apps")
            return
        }

        // Block selected apps
        store.shield.applications = tokens.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            tokens.categoryTokens)

        // Block web domains if needed
        store.shield.webDomains = tokens.webDomainTokens
        store.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            tokens.categoryTokens)

        print("Apps blocked successfully")
    }

    func unblockAllApps() {
        guard isAuthorized else {
            print("Not authorized to unblock apps")
            return
        }

        // Clear all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil

        print("All apps unblocked")
    }

    // MARK: - Shield Configuration

    func configureShield() {
        // Customize the shield appearance
        // This will show when users try to open blocked apps
        store.shield.applications = store.shield.applications
    }

    // MARK: - Check if blocking is active

    func isBlockingActive() -> Bool {
        return isAuthorized
            && (store.shield.applications != nil || store.shield.applicationCategories != nil)
    }
}

// MARK: - Legacy Support (Pre-iOS 16)

class LegacyAppBlockingManager: ObservableObject {

    static let shared = LegacyAppBlockingManager()

    @Published var blockedAppIdentifiers: [String] = []

    func recordBlockedApps(_ identifiers: [String]) {
        self.blockedAppIdentifiers = identifiers
        print("Recorded \(identifiers.count) apps to block (manual Screen Time setup required)")
    }

    func clearBlockedApps() {
        self.blockedAppIdentifiers = []
        print("Cleared blocked apps list")
    }

    func openScreenTimeSettings() {
        if let url = URL(string: "App-prefs:ScreenTime") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}
