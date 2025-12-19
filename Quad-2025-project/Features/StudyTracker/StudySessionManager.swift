//
//  StudySessionManager.swift
//  Quad-2025-project
//
//  Manages study sessions, timer, and Firebase integration
//

import Combine
import DeviceActivity
import FamilyControls
import FirebaseAuth
import FirebaseFirestore
import Foundation
import ManagedSettings
import UserNotifications

@MainActor
class StudySessionManager: ObservableObject {
    @Published var currentSession: StudySession?
    @Published var sessions: [StudySession] = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var isStudying: Bool = false
    @Published var blockedApps: [BlockedApp] = BlockedApp.commonApps
    @Published var weeklyData: [WeeklyStudyData] = []
    @Published var isScreenTimeAuthorized: Bool = false
    @Published var selectedAppsForBlocking = FamilyActivitySelection()
    @Published var errorMessage: String = ""

    private var isPaused: Bool = false  // Track if session is manually paused

    private var timer: Timer?
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let authCenter = AuthorizationCenter.shared
    private let managedSettingsStore = ManagedSettingsStore()

    init() {
        loadBlockedAppsSettings()
        startListening()
        calculateWeeklyData()
        checkScreenTimeAuthorization()
    }

    deinit {
        timer?.invalidate()
        listener?.remove()
    }

    // MARK: - Timer Control

    func startStudySession() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user authenticated")
            return
        }

        let selectedApps = blockedApps.filter { $0.isBlocked }.map { $0.bundleIdentifier }
        let now = Date()

        let session = StudySession(
            userId: userId,
            startTime: now,
            endTime: nil,
            duration: 0,
            isActive: true,
            blockedApps: selectedApps,
            date: now
        )

        // Save to Firestore with explicit timestamp encoding
        let sessionData: [String: Any] = [
            "userId": session.userId,
            "startTime": Timestamp(date: session.startTime),
            "endTime": NSNull(),
            "duration": session.duration,
            "isActive": session.isActive,
            "blockedApps": session.blockedApps,
            "date": Timestamp(date: session.date),
        ]

        let ref = db.collection("studySessions").document()
        ref.setData(sessionData) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error starting study session: \(error.localizedDescription)")
                return
            }

            var newSession = session
            newSession.id = ref.documentID

            Task { @MainActor in
                self.currentSession = newSession
                self.isStudying = true
                self.isPaused = false  // Clear any paused state
                self.elapsedTime = 0
                self.startTimer()
                self.scheduleLocalNotification()
                print("✅ Study session started: \(ref.documentID)")

                // Apply app blocking if authorized
                self.applyAppBlocking()
            }
        }
    }

    func pauseStudySession() {
        // Stop and clear timer completely
        timer?.invalidate()
        timer = nil
        isStudying = false
        isPaused = true  // Mark as paused

        print("⏸️ Study session paused - Timer stopped")

        // Update Firestore to mark session as inactive (paused)
        if let sessionId = currentSession?.id {
            let updateData: [String: Any] = [
                "isActive": false,
                "duration": elapsedTime,
            ]

            db.collection("studySessions").document(sessionId).updateData(updateData) { error in
                if let error = error {
                    print("❌ Error pausing session: \(error.localizedDescription)")
                } else {
                    print("✅ Study session paused and saved to Firestore")
                }
            }
        }
    }

    func resumeStudySession() {
        isPaused = false  // Clear paused flag
        isStudying = true
        startTimer()

        // Update Firestore to mark session as active again
        if let sessionId = currentSession?.id {
            db.collection("studySessions").document(sessionId).updateData([
                "isActive": true
            ]) { error in
                if let error = error {
                    print("❌ Error resuming session: \(error.localizedDescription)")
                } else {
                    print("▶️ Study session resumed and saved to Firestore")
                }
            }
        }

        print("▶️ Study session resumed")
    }

    func endStudySession() {
        guard var session = currentSession else { return }

        timer?.invalidate()
        timer = nil

        let endTime = Date()
        session.endTime = endTime
        session.isActive = false
        session.duration = elapsedTime

        // Update Firestore with explicit timestamp encoding
        if let sessionId = session.id {
            let updateData: [String: Any] = [
                "endTime": Timestamp(date: endTime),
                "isActive": false,
                "duration": elapsedTime,
            ]

            db.collection("studySessions").document(sessionId).updateData(updateData) {
                [weak self] error in
                if let error = error {
                    print("❌ Error ending study session: \(error.localizedDescription)")
                } else if let self = self {
                    Task { @MainActor in
                        print(
                            "✅ Study session ended: \(sessionId), Duration: \(self.formattedTime(self.elapsedTime))"
                        )
                    }
                }
            }
        }

        // Remove app blocking
        removeAppBlocking()

        currentSession = nil
        isStudying = false
        isPaused = false  // Clear paused flag
        elapsedTime = 0

        // Cancel any pending notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "studyReminder"
        ])

        // Refresh weekly data
        calculateWeeklyData()
    }

    private func startTimer() {
        // Clear any existing timer first
        timer?.invalidate()
        timer = nil

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // Only increment if actually studying (not paused)
                guard self.isStudying && !self.isPaused else {
                    print("⚠️ Timer fired but not studying - stopping timer")
                    self.timer?.invalidate()
                    self.timer = nil
                    return
                }

                self.elapsedTime += 1

                // Auto-save every 30 seconds
                if Int(self.elapsedTime) % 30 == 0 {
                    self.updateCurrentSession()
                }
            }
        }
    }

    private func updateCurrentSession() {
        guard let session = currentSession, let sessionId = session.id else { return }

        let updateData: [String: Any] = [
            "duration": elapsedTime
        ]

        db.collection("studySessions").document(sessionId).updateData(updateData) {
            [weak self] error in
            if let error = error {
                print("❌ Error updating study session: \(error.localizedDescription)")
            } else if let self = self {
                Task { @MainActor in
                    print("💾 Session auto-saved: \(self.formattedTime(self.elapsedTime))")
                }
            }
        }
    }

    // MARK: - Firestore Listeners

    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user ID for listening to sessions")
            return
        }

        print("👂 Starting to listen for study sessions...")

        listener = db.collection("studySessions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error fetching study sessions: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found")
                    return
                }

                print("📥 Received \(documents.count) study sessions")

                let fetchedSessions = documents.compactMap { doc -> StudySession? in
                    do {
                        let session = try doc.data(as: StudySession.self)
                        return session
                    } catch {
                        print("❌ Error decoding session: \(error.localizedDescription)")
                        return nil
                    }
                }

                Task { @MainActor in
                    self.sessions = fetchedSessions
                    print("✅ Loaded \(fetchedSessions.count) sessions")

                    // Check if there's an active session
                    if let activeSession = fetchedSessions.first(where: { $0.isActive }) {
                        print("🔄 Found active session: \(activeSession.id ?? "unknown")")

                        // Only auto-resume if:
                        // 1. We don't already have this session
                        // 2. Session is not manually paused
                        if self.currentSession?.id != activeSession.id && !self.isPaused {
                            self.currentSession = activeSession

                            // If the app was closed and reopened, calculate elapsed time
                            let timeSinceStart = Date().timeIntervalSince(activeSession.startTime)
                            self.elapsedTime = max(timeSinceStart, activeSession.duration)

                            if self.isStudying == false {
                                self.isStudying = true
                                self.startTimer()
                                print("▶️ Resumed active session")
                            }
                        } else if self.isPaused {
                            print("⏸️ Session is paused, not auto-resuming")
                            // Update current session to paused one
                            self.currentSession = activeSession
                            self.elapsedTime = activeSession.duration
                        }
                    } else if self.currentSession != nil && !self.isPaused {
                        // If we had an active session but now there's none and not paused
                        // It was likely paused by this device - don't treat as remote end
                        if !fetchedSessions.contains(where: {
                            $0.id == self.currentSession?.id && !$0.isActive
                        }) {
                            // Session truly doesn't exist anymore
                            print("⚠️ Session ended remotely")
                            self.timer?.invalidate()
                            self.timer = nil
                            self.isStudying = false
                            self.currentSession = nil
                            self.elapsedTime = 0
                        } else {
                            print("ℹ️ Session found but inactive (paused)")
                        }
                    }

                    self.calculateWeeklyData()
                }
            }
    }

    // MARK: - Blocked Apps Management

    func toggleAppBlock(for app: BlockedApp) {
        if let index = blockedApps.firstIndex(where: { $0.id == app.id }) {
            blockedApps[index].isBlocked.toggle()
            saveBlockedAppsSettings()
        }
    }

    func addCustomApp(name: String, bundleIdentifier: String) {
        let newApp = BlockedApp(name: name, bundleIdentifier: bundleIdentifier, isBlocked: true)
        blockedApps.append(newApp)
        saveBlockedAppsSettings()
    }

    func removeApp(at offsets: IndexSet) {
        blockedApps.remove(atOffsets: offsets)
        saveBlockedAppsSettings()
    }

    private func saveBlockedAppsSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let appsData = blockedApps.map { app -> [String: Any] in
            return [
                "name": app.name,
                "bundleIdentifier": app.bundleIdentifier,
                "isBlocked": app.isBlocked,
            ]
        }

        db.collection("users").document(userId).setData(
            [
                "blockedApps": appsData
            ], merge: true)
    }

    private func loadBlockedAppsSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error loading blocked apps: \(error.localizedDescription)")
                return
            }

            if let data = snapshot?.data(),
                let appsData = data["blockedApps"] as? [[String: Any]]
            {

                let loadedApps = appsData.compactMap { appDict -> BlockedApp? in
                    guard let name = appDict["name"] as? String,
                        let bundleId = appDict["bundleIdentifier"] as? String,
                        let isBlocked = appDict["isBlocked"] as? Bool
                    else {
                        return nil
                    }
                    return BlockedApp(name: name, bundleIdentifier: bundleId, isBlocked: isBlocked)
                }

                if !loadedApps.isEmpty {
                    DispatchQueue.main.async {
                        self.blockedApps = loadedApps
                    }
                }
            }
        }
    }

    // MARK: - Weekly Data Calculation

    func calculateWeeklyData() {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)

        // Calculate start of week (Monday)
        let daysFromMonday = (weekday + 5) % 7
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)
        else {
            return
        }

        let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var weeklyData: [WeeklyStudyData] = []

        for (index, day) in weekDays.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: index, to: startOfWeek) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            // Sum all sessions for this day
            let dayHours =
                sessions
                .filter { session in
                    session.startTime >= dayStart && session.startTime < dayEnd && !session.isActive
                }
                .reduce(0.0) { $0 + $1.durationInHours }

            weeklyData.append(WeeklyStudyData(day: day, hours: dayHours, date: date))
        }

        DispatchQueue.main.async {
            self.weeklyData = weeklyData
        }
    }

    // MARK: - Statistics

    func getTodayStudyTime() -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        let todaySessions = sessions.filter { session in
            session.startTime >= today && session.startTime < tomorrow
        }

        let totalTime = todaySessions.reduce(0.0) { $0 + $1.duration }

        // Add current session time if studying
        if isStudying {
            return totalTime + elapsedTime
        }

        return totalTime
    }

    func getWeekStudyTime() -> TimeInterval {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7

        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)
        else {
            return 0
        }

        let weekStart = calendar.startOfDay(for: startOfWeek)

        let weekSessions = sessions.filter { session in
            session.startTime >= weekStart && !session.isActive
        }

        return weekSessions.reduce(0.0) { $0 + $1.duration }
    }

    func getAverageStudyTime() -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7

        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)
        else {
            return 0
        }

        let weekStart = calendar.startOfDay(for: startOfWeek)
        let daysInWeek = daysFromMonday + 1  // Including today

        let weekSessions = sessions.filter { session in
            session.startTime >= weekStart && !session.isActive
        }

        let totalTime = weekSessions.reduce(0.0) { $0 + $1.duration }

        return daysInWeek > 0 ? totalTime / Double(daysInWeek) : 0
    }

    // MARK: - Notifications

    private func scheduleLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Stay Focused!"
        content.body = "Keep up the good work. You're doing great!"
        content.sound = .default

        // Send notification after 30 minutes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)
        let request = UNNotificationRequest(
            identifier: "studyReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            if let error = error {
                print("❌ Error requesting notification permission: \(error.localizedDescription)")
            } else if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }

    // MARK: - Screen Time API Integration

    func checkScreenTimeAuthorization() {
        let status = authCenter.authorizationStatus
        self.isScreenTimeAuthorized = (status == .approved)
        print(
            "📱 Screen Time authorization status: \(status == .approved ? "Approved" : "Not Approved")"
        )
    }

    func requestScreenTimeAuthorization() async {
        do {
            try await authCenter.requestAuthorization(for: .individual)
            self.checkScreenTimeAuthorization()
            print("✅ Screen Time authorization requested")
        } catch {
            let errorMessage = error.localizedDescription
            print("❌ Failed to request Screen Time authorization: \(errorMessage)")

            // Check if it's the "only one application" error
            if errorMessage.contains("only one application at a time") {
                print("⚠️ Screen Time is already authorized for another app")
                print("💡 Solution: Go to Settings → Screen Time → Content & Privacy Restrictions")
                print("   Then disable and re-enable Screen Time, or delete the other app")

                self.errorMessage =
                    "Screen Time is already in use by another app. Please go to Settings → Screen Time to reset it, or delete/reinstall this app."
            } else {
                self.errorMessage = errorMessage
            }
        }
    }

    func applyAppBlocking() {
        guard isScreenTimeAuthorized else {
            print("⚠️ Screen Time not authorized - cannot block apps")
            return
        }

        // Apply app blocking using selected apps
        if !selectedAppsForBlocking.applicationTokens.isEmpty {
            managedSettingsStore.shield.applications = selectedAppsForBlocking.applicationTokens
            managedSettingsStore.shield.applicationCategories = .specific(
                selectedAppsForBlocking.categoryTokens)
            print("🔒 \(selectedAppsForBlocking.applicationTokens.count) apps blocked")
        }
    }

    func removeAppBlocking() {
        guard isScreenTimeAuthorized else {
            return
        }

        // Remove all app blocking
        managedSettingsStore.shield.applications = nil
        managedSettingsStore.shield.applicationCategories = nil
        print("🔓 All apps unblocked")
    }

    // MARK: - Formatted Time Strings

    func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
