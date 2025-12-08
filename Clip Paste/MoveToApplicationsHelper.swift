import AppKit

enum MoveToApplicationsHelper {

    /// Returns `false` if the app is being relaunched or terminated and
    /// you should stop further launch work. Returns `true` to continue.
    @discardableResult
    static func moveIfNeeded() -> Bool {
        let bundleURL = Bundle.main.bundleURL
        let bundlePath = bundleURL.deletingLastPathComponent().path

        // Accept both /Applications and ~/Applications
        let allowedParentPaths: [String] = [
            "/Applications",
            ("~/Applications" as NSString).expandingTildeInPath
        ]

        // Already in an Applications folder — nothing to do.
        if allowedParentPaths.contains(bundlePath) {
            return true
        }

        // Ask the user
        let alert = NSAlert()
        alert.messageText = "Move Clip Paste to the Applications folder?"
        alert.informativeText = """
        It’s recommended to keep Clip Paste in the Applications folder \
        to avoid macOS translocation issues and to make updates work reliably.
        """
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Don’t Move")

        let response = alert.runModal()
        if response != .alertFirstButtonReturn {
            // User chose “Don’t Move” → continue launching from current location.
            return true
        }

        let fileManager = FileManager.default
        let destinationDir = URL(fileURLWithPath: "/Applications", isDirectory: true)
        let destinationURL = destinationDir.appendingPathComponent(bundleURL.lastPathComponent)

        do {
            // If an app already exists in /Applications, try to remove it so we can replace it.
            if fileManager.fileExists(atPath: destinationURL.path) {
                do {
                    try fileManager.removeItem(at: destinationURL)
                } catch {
                    // If we can't remove the existing app, just launch that one instead.
                    NSWorkspace.shared.openApplication(at: destinationURL,
                                                       configuration: .init(),
                                                       completionHandler: nil)
                    NSApp.terminate(nil)
                    return false
                }
            }

            // Try to move the running app bundle into /Applications.
            do {
                try fileManager.moveItem(at: bundleURL, to: destinationURL)
            } catch {
                // Moving can fail if the source is on a read-only volume (e.g. DMG).
                // Fallback: copy, then best-effort delete the original.
                try fileManager.copyItem(at: bundleURL, to: destinationURL)
                _ = try? fileManager.removeItem(at: bundleURL)
            }

            // Launch the app from its new home.
            NSWorkspace.shared.openApplication(at: destinationURL,
                                               configuration: .init(),
                                               completionHandler: nil)

            // Terminate the current (old) instance.
            NSApp.terminate(nil)
            return false
        } catch {
            let errorAlert = NSAlert(error: error)
            errorAlert.messageText = "Couldn’t Move Clip Paste"
            errorAlert.informativeText = """
            Clip Paste couldn’t be moved to the Applications folder.
            You can still use it from its current location.
            """
            errorAlert.runModal()
            return true
        }
    }
}
