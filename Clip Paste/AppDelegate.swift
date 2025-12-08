import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start hidden in Dock
        NSApp.setActivationPolicy(.accessory)

        registerShortcutHandler()

        // Show settings on first manual launch
        // For simplicity, we always show settings when the app is launched
        showSettings()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running even when settings window is closed
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When user clicks app icon or launches again, show settings
        showSettings()
        return false
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(rootView: SettingsView())
        }

        guard let window = settingsWindowController?.window else { return }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        window.makeKeyAndOrderFront(nil)
    }

    func hideSettings() {
        // Called when the settings window closes
        NSApp.setActivationPolicy(.accessory)
    }

    private func registerShortcutHandler() {
        KeyboardShortcuts.onKeyDown(for: .smartPaste) {
            ClipboardHandler.handleSmartPaste()
        }
    }
}
