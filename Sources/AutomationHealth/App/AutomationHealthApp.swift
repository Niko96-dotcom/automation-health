import AppKit
import Sparkle
import SwiftUI
import ActiveJobsCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct AutomationHealthApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var preferences: PreferencesStore
    @StateObject private var store: JobStore
    @StateObject private var updateStore: UpdateStore

    init() {
        let prefs = PreferencesStore()
        _preferences = StateObject(wrappedValue: prefs)
        _store = StateObject(wrappedValue: JobStore(preferences: prefs))

        let updaterDelegate = UpdateStoreDelegate() // store: will be set below

        let userDriver = SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil)
        let sparkleUpdater = SPUUpdater(
            hostBundle: Bundle.main,
            applicationBundle: Bundle.main,
            userDriver: userDriver,
            delegate: updaterDelegate
        )
        let store = UpdateStore(updater: sparkleUpdater)
        updaterDelegate.store = store
        _updateStore = StateObject(wrappedValue: store)
    }

    var body: some Scene {
        WindowGroup("Automation Health", id: "main") {
            ContentView(store: store, preferences: preferences)
                .frame(minWidth: 980, minHeight: 620)
                .task {
                    if preferences.scanOnLaunch {
                        store.refresh()
                    }
                }
                .task {
                    updateStore.startUpdater()
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates\u{2026}") {
                    updateStore.checkForUpdates()
                }
                .disabled(!updateStore.canCheckForUpdates)
            }

            CommandMenu("View") {
                Button("Focus Search Field") {
                    preferences.requestSearchFieldFocus = true
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Divider()

                Button("Expand All Sections") {
                    preferences.sidebarExpandAllOverride = true
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Collapse All Sections") {
                    preferences.sidebarExpandAllOverride = false
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])

                Divider()

                Button("Group by Source") {
                    preferences.groupingMode = .source
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Group by Origin") {
                    preferences.groupingMode = .origin
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Group by Health") {
                    preferences.groupingMode = .health
                }
                .keyboardShortcut("3", modifiers: [.command])

                Button("Group by Trigger") {
                    preferences.groupingMode = .trigger
                }
                .keyboardShortcut("4", modifiers: [.command])

                Button("Group by Confidence") {
                    preferences.groupingMode = .confidence
                }
                .keyboardShortcut("5", modifiers: [.command])

                Button("Group by Schedule") {
                    preferences.groupingMode = .schedule
                }
                .keyboardShortcut("6", modifiers: [.command])
            }

            CommandMenu("Automations") {
                Button("Rescan Automations") {
                    store.refresh()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        Settings {
            SettingsView(preferences: preferences, updateStore: updateStore)
        }
    }
}
