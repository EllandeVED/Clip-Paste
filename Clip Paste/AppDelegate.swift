import AppKit
import KeyboardShortcuts
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: NSWindowController?
    // Tracks whether the initial launch flow has created a settings window at least once.
    private var hasCreatedSettingsWindow = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // If a move+relaunch is in progress, stop here.
        if !MoveToApplicationsHelper.moveIfNeeded() {
            return
        }

        // Start hidden in Dock
        NSApp.setActivationPolicy(.accessory)

        registerShortcutHandler()
        CPUpdateChecker.shared.checkOnLaunch()

        #if DEBUG
        // In Debug builds (e.g. running from Xcode), always show the welcome window
        // so it appears on every run for testing.
        showOnboarding()
        #else
        // In Release / distributed builds, only show onboarding the first time
        // for this specific installed copy of the app (bundle path–based key),
        // so cached data from other instances (e.g. Debug builds) is ignored.
        let installID = Bundle.main.bundleURL.resolvingSymlinksInPath().path
        let onboardingKey = "hasSeenOnboarding::" + installID
        if !UserDefaults.standard.bool(forKey: onboardingKey) {
            showOnboarding()
        } else {
            showSettings()
        }
        #endif
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running even when settings window is closed
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Only reopen the settings window if one has already been created by the initial flow.
        // This avoids creating a settings window before the move popup or onboarding.
        guard hasCreatedSettingsWindow, let window = settingsWindowController?.window else {
            return false
        }

        if !window.isVisible {
            showSettings()
        } else {
            window.makeKeyAndOrderFront(nil)
        }
        return false
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(rootView: SettingsView())
            hasCreatedSettingsWindow = true
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
    private func showOnboarding() {
        if onboardingWindowController == nil {
            let onboardingKey: String = {
                #if DEBUG
                return "hasSeenOnboardingDebug"
                #else
                let installID = Bundle.main.bundleURL.resolvingSymlinksInPath().path
                return "hasSeenOnboarding::" + installID
                #endif
            }()

            let contentView = ClipPasteOnboardingView(isPresented: .init(
                get: { self.onboardingWindowController != nil },
                set: { newValue in
                    if !newValue {
                        // Treat any dismissal (Continue button or red close button)
                        // as “onboarding has been shown once”.
                        UserDefaults.standard.set(true, forKey: onboardingKey)

                        // Onboarding finished: close and show settings
                        self.onboardingWindowController?.close()
                        self.onboardingWindowController = nil
                        self.showSettings()
                    }
                }
            ))

            let hosting = NSHostingController(rootView: contentView)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Welcome to Clip Paste"
            window.contentViewController = hosting

            onboardingWindowController = NSWindowController(window: window)
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindowController?.showWindow(nil)
    }
}
