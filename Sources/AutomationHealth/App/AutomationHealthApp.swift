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
