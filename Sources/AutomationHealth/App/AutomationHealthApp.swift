import AppKit
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

    init() {
        let prefs = PreferencesStore()
        _preferences = StateObject(wrappedValue: prefs)
        _store = StateObject(wrappedValue: JobStore(preferences: prefs))
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
        }
        .commands {
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
            }

            CommandMenu("Automations") {
                Button("Rescan Automations") {
                    store.refresh()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        Settings {
            SettingsView(preferences: preferences)
        }
    }
}
