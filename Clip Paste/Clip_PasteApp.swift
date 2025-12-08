import SwiftUI
import AppKit
import KeyboardShortcuts
import LaunchAtLogin

@main
struct PasteHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We do not show a default WindowGroup. Settings are handled manually
        Settings {
            SettingsView()
                .frame(minWidth: 420, idealWidth: 480, minHeight: 320, idealHeight: 380)
        }
    }
}
