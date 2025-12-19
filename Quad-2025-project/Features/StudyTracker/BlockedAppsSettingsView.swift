//
//  BlockedAppsSettingsView.swift
//  Quad-2025-project
//
//  Settings view for managing blocked apps during study sessions
//

import SwiftUI

struct BlockedAppsSettingsView: View {
    @ObservedObject var sessionManager: StudySessionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var showAddCustomApp = false
    @State private var showInfoView = false
    @State private var customAppName = ""
    @State private var customAppBundle = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(
                        "Select which apps to block during study sessions. These apps will be restricted when you start studying."
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                }

                Section(header: Text("Social Media & Entertainment")) {
                    ForEach(socialMediaApps) { app in
                        appToggleRow(app: app)
                    }
                }

                Section(header: Text("Productivity Apps")) {
                    ForEach(productivityApps) { app in
                        appToggleRow(app: app)
                    }
                }

                Section(header: Text("Custom Apps")) {
                    ForEach(customApps) { app in
                        appToggleRow(app: app)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let index = sessionManager.blockedApps.firstIndex(where: {
                                        $0.id == app.id
                                    }) {
                                        sessionManager.blockedApps.remove(at: index)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }

                    Button {
                        showAddCustomApp = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color("UTAustinOrange"))
                            Text("Add Custom App")
                        }
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("\(sessionManager.blockedApps.filter { $0.isBlocked }.count)")
                                .font(.title)
                                .bold()
                                .foregroundColor(Color("UTAustinOrange"))
                            Text("Apps will be blocked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Blocked Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showInfoView = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color("UTAustinOrange"))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(Color("UTAustinOrange"))
                }
            }
            .sheet(isPresented: $showAddCustomApp) {
                addCustomAppSheet
            }
            .sheet(isPresented: $showInfoView) {
                AppBlockingInfoView()
            }
        }
    }

    // MARK: - App Toggle Row

    func appToggleRow(app: BlockedApp) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.body)
                Text(app.bundleIdentifier)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: binding(for: app))
                .tint(Color("UTAustinOrange"))
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    func binding(for app: BlockedApp) -> Binding<Bool> {
        Binding(
            get: {
                sessionManager.blockedApps.first(where: { $0.id == app.id })?.isBlocked ?? false
            },
            set: { newValue in
                if let index = sessionManager.blockedApps.firstIndex(where: { $0.id == app.id }) {
                    sessionManager.blockedApps[index].isBlocked = newValue
                    sessionManager.toggleAppBlock(for: app)
                }
            }
        )
    }

    // MARK: - Add Custom App Sheet

    var addCustomAppSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("App Information")) {
                    TextField("App Name", text: $customAppName)
                        .autocapitalization(.words)

                    TextField("Bundle Identifier", text: $customAppBundle)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }

                Section {
                    Text(
                        "Enter the app's bundle identifier (e.g., com.company.appname). You can find this in the app's Info.plist or on developer documentation."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Custom App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        customAppName = ""
                        customAppBundle = ""
                        showAddCustomApp = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if !customAppName.isEmpty && !customAppBundle.isEmpty {
                            sessionManager.addCustomApp(
                                name: customAppName, bundleIdentifier: customAppBundle)
                            customAppName = ""
                            customAppBundle = ""
                            showAddCustomApp = false
                        }
                    }
                    .bold()
                    .foregroundColor(Color("UTAustinOrange"))
                    .disabled(customAppName.isEmpty || customAppBundle.isEmpty)
                }
            }
        }
    }

    // MARK: - Computed Properties

    var socialMediaApps: [BlockedApp] {
        let socialBundles = [
            "com.burbn.instagram",
            "com.zhiliaoapp.musically",
            "com.atebits.Tweetie2",
            "com.facebook.Facebook",
            "com.toyopagroup.picaboo",
            "com.google.ios.youtube",
            "com.reddit.Reddit",
            "com.hammerandchisel.discord",
            "tv.twitch",
            "com.netflix.Netflix",
        ]

        return sessionManager.blockedApps.filter { app in
            socialBundles.contains(app.bundleIdentifier)
        }
    }

    var productivityApps: [BlockedApp] {
        let productivityBundles = [
            "com.spotify.client",
            "com.apple.mobilesafari",
            "com.apple.MobileSMS",
            "com.apple.mobilemail",
        ]

        return sessionManager.blockedApps.filter { app in
            productivityBundles.contains(app.bundleIdentifier)
        }
    }

    var customApps: [BlockedApp] {
        let knownBundles = [
            "com.burbn.instagram",
            "com.zhiliaoapp.musically",
            "com.atebits.Tweetie2",
            "com.facebook.Facebook",
            "com.toyopagroup.picaboo",
            "com.google.ios.youtube",
            "com.reddit.Reddit",
            "com.hammerandchisel.discord",
            "tv.twitch",
            "com.netflix.Netflix",
            "com.spotify.client",
            "com.apple.mobilesafari",
            "com.apple.MobileSMS",
            "com.apple.mobilemail",
        ]

        return sessionManager.blockedApps.filter { app in
            !knownBundles.contains(app.bundleIdentifier)
        }
    }
}

#Preview {
    BlockedAppsSettingsView(sessionManager: StudySessionManager())
}
