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
    @StateObject private var store = JobStore()

    var body: some Scene {
        WindowGroup("Automation Health", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 980, minHeight: 620)
                .task {
                    store.refresh()
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
    }
}
