import AppKit

enum ClipboardHandler {
    private static var lastAutomationNotAuthorized = false

    static func handleSmartPaste() {
        print("[Clip Paste] handleSmartPaste called")
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
        print("[Clip Paste] Frontmost app: \(frontmost)")
        print("[Clip Paste] isFinderFrontmost: \(isFinderFrontmost)")
        
        let pasteboard = NSPasteboard.general
        print("[Clip Paste] Clipboard types: \(pasteboard.types ?? [])")
        
        if clipboardContainsFiles(pasteboard: pasteboard) {
            print("[Clip Paste] Clipboard contains file URLs, leaving normal paste behavior to Finder / app")
            return
        }
        
        if Preferences.isImageBehaviorEnabled, let image = clipboardImage(pasteboard: pasteboard) {
            print("[Clip Paste] Image detected on clipboard")
            createImageFile(from: image)
            return
        }
        
        if Preferences.isTextBehaviorEnabled, let text = clipboardText(pasteboard: pasteboard) {
            print("[Clip Paste] Text detected on clipboard: \(text.prefix(80))")
            createTextFile(from: text)
            return
        }
        
        print("[Clip Paste] No matching clipboard content for smart paste (no image/text or behaviors disabled)")
    }

    private static var isFinderFrontmost: Bool {
        let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return bundleIdentifier == "com.apple.finder"
    }

    private static func clipboardContainsFiles(pasteboard: NSPasteboard) -> Bool {
        return pasteboard.types?.contains(.fileURL) == true
    }

    private static func clipboardImage(pasteboard: NSPasteboard) -> NSImage? {
        if let image = NSImage(pasteboard: pasteboard) {
            print("[Clip Paste] clipboardImage extracted: <NSImage>")
            return image
        }
        print("[Clip Paste] clipboardImage extracted: nil (no NSImage)")
        return nil
    }
    
    private static func clipboardImageName(pasteboard: NSPasteboard) -> String? {
        // Try to infer a name from file URLs on the pasteboard, if any
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first {
            let base = url.deletingPathExtension().lastPathComponent
            if !base.isEmpty {
                print("[Clip Paste] clipboardImageName inferred from URL: \(base)")
                return base
            }
        }
        // Detect screenshots on the pasteboard (e.g. from macOS screenshot shortcuts)
        if let types = pasteboard.types {
            if types.contains(NSPasteboard.PasteboardType("com.apple.screencapture")) {
                print("[Clip Paste] clipboardImageName: detected screenshot via com.apple.screencapture; using 'screenshot'")
                return "screenshot"
            }
            if types.contains(NSPasteboard.PasteboardType("com.apple.screencapture.type")) {
                print("[Clip Paste] clipboardImageName: detected screenshot via com.apple.screencapture.type; using 'screenshot'")
                return "screenshot'"
            }

            // Fallback: if there is image data but no explicit name, treat it as a screenshot-like image
            let imageUTIs = [
                "public.png",
                "public.tiff",
                "public.jpeg",
                "public.heic",
                "public.bmp"
            ]
            let hasImageType = types.contains { type in
                imageUTIs.contains(type.rawValue)
            }
            if hasImageType {
                print("[Clip Paste] clipboardImageName: no explicit name but image data present; using 'screenshot' as default name")
                return "screenshot"
            }
        }

        print("[Clip Paste] clipboardImageName: nil (no suitable source name)")
        return nil
    }

    private static func clipboardText(pasteboard: NSPasteboard) -> String? {
        if let text = pasteboard.string(forType: .string) {
            print("[Clip Paste] clipboardText extracted: \"\(text.prefix(80))\"")
            return text
        } else {
            print("[Clip Paste] clipboardText extracted: nil")
            return nil
        }
    }

    private static func saveDirectoryURL() -> URL? {
        if isFinderFrontmost {
            print("[Clip Paste] Finder is frontmost, trying to resolve frontmost folder via AppleScript")
            if let finderURL = finderFrontmostDirectoryURL() {
                print("[Clip Paste] saveDirectoryURL (Finder frontmost) -> \(finderURL.path)")
                return finderURL
            } else {
                if lastAutomationNotAuthorized {
                    print("[Clip Paste] Not authorized to control Finder; will NOT fall back to default save location")
                    return nil
                } else {
                    print("[Clip Paste] Could not resolve Finder frontmost folder (not an authorization issue), falling back to default save location (if enabled)")
                }
            }
        }

        if !Preferences.isDefaultSaveEnabled {
            print("[Clip Paste] Default save location is disabled and Finder folder could not be resolved; aborting smart paste.")
            return nil
        }
        
        guard let defaultURL = defaultSaveDirectoryURL() else {
            print("[Clip Paste] defaultSaveDirectoryURL returned nil")
            return nil
        }
        print("[Clip Paste] saveDirectoryURL (default) -> \(defaultURL.path) for location \(Preferences.saveLocation)")
        print("[Clip Paste] This folder is used when Finder is not frontmost or when the Finder folder cannot be resolved (and default save is enabled).")
        return defaultURL
    }
    
    private static func defaultSaveDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        let domain: FileManager.SearchPathDomainMask = .userDomainMask
        
        let directory: FileManager.SearchPathDirectory
        switch Preferences.saveLocation {
        case .desktop:
            directory = .desktopDirectory
        case .downloads:
            directory = .downloadsDirectory
        case .pictures:
            directory = .picturesDirectory
        }
        
        let url = fileManager.urls(for: directory, in: domain).first
        return url
    }
    
    private static func finderFrontmostDirectoryURL() -> URL? {
        let scriptSource = """
        tell application "Finder"
            if (count of windows) is 0 then
                return POSIX path of (desktop as alias)
            else
                set targetFolder to (target of front window) as alias
                return POSIX path of targetFolder
            end if
        end tell
        """
        
        guard let script = NSAppleScript(source: scriptSource) else {
            print("[Clip Paste] Failed to create NSAppleScript for Finder frontmost directory")
            return nil
        }
        
        var errorDict: NSDictionary?
        let output = script.executeAndReturnError(&errorDict)
        
        if let errorDict = errorDict {
            print("[Clip Paste] NSAppleScript error while resolving Finder frontmost directory: \(errorDict)")
            if let errorNumber = errorDict[NSAppleScript.errorNumber] as? Int, errorNumber == -1743 {
                print("[Clip Paste] Not authorized to send Apple events to Finder (error -1743)")
                lastAutomationNotAuthorized = true
                showAutomationPermissionAlertIfNeeded()
                return nil
            } else {
                lastAutomationNotAuthorized = false
            }
        } else {
            lastAutomationNotAuthorized = false
        }
        
        guard let path = output.stringValue else {
            print("[Clip Paste] NSAppleScript returned no string for Finder frontmost directory")
            return nil
        }
        
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[Clip Paste] NSAppleScript raw path: '\(path)'")
        print("[Clip Paste] NSAppleScript trimmed path: '\(trimmedPath)'")
        
        let url = URL(fileURLWithPath: trimmedPath)
        return url
    }

    private static func createImageFile(from image: NSImage) {
        guard let folderURL = saveDirectoryURL() else {
            return
        }

        let date = Date()
        let counter = Preferences.nextImageCounter()
        let name = clipboardImageName(pasteboard: NSPasteboard.general)
        let context = FilenameTemplateContext(
            date: date,
            clipboardText: nil,
            clipboardName: name,
            counter: counter
        )

        let baseName = FilenameTemplate.expand(
            template: Preferences.imageFilenameTemplate,
            context: context
        )

        let fileURL = folderURL.appendingPathComponent(baseName).appendingPathExtension("png")

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }

        print("[Clip Paste] Image file will be written to: \(fileURL.path)")
        do {
            try pngData.write(to: fileURL, options: .atomic)
            print("[Clip Paste] Image file successfully written to: \(fileURL.path)")
        } catch {
            let nsError = error as NSError
            print("[Clip Paste] Error writing image file: \(nsError) (code: \(nsError.code))")
            if nsError.code == 513 {
                print("[Clip Paste] Hint: error 513 usually means macOS is blocking access to this folder (Files & Folders, sandbox, or iCloud permissions).")
                showFileWritePermissionAlert(for: fileURL, error: nsError)
            }
        }
    }

    private static func createTextFile(from text: String) {
        guard let folderURL = saveDirectoryURL() else {
            return
        }

        let date = Date()
        let counter = Preferences.nextTextCounter()
        let context = FilenameTemplateContext(
            date: date,
            clipboardText: text,
            clipboardName: nil,
            counter: counter
        )

        let baseName = FilenameTemplate.expand(
            template: Preferences.textFilenameTemplate,
            context: context
        )

        let fileURL = folderURL.appendingPathComponent(baseName).appendingPathExtension("txt")

        print("[Clip Paste] Text file will be written to: \(fileURL.path)")
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("[Clip Paste] Text file successfully written to: \(fileURL.path)")
        } catch {
            let nsError = error as NSError
            print("[Clip Paste] Error writing text file: \(nsError) (code: \(nsError.code))")
            if nsError.code == 513 {
                print("[Clip Paste] Hint: error 513 usually means macOS is blocking access to this folder (Files & Folders, sandbox, or iCloud permissions).")
                showFileWritePermissionAlert(for: fileURL, error: nsError)
            }
        }
    }

    private static func showAutomationPermissionAlertIfNeeded() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Allow Clip Paste to control Finder"
            alert.informativeText = """
            To save files in the current Finder folder, macOS needs permission to let Clip Paste control Finder.

            Click “Open System Settings” and then enable Clip Paste under Finder in:
            System Settings → Privacy & Security → Automation.
            """
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                } else {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                }
            }
        }
    }

    private static func showFileWritePermissionAlert(for fileURL: URL, error: NSError) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Cannot write file"
            alert.informativeText = """
            Clip Paste tried to save a file here:

            \(fileURL.path)

            but macOS reported a permissions error (code \(error.code)).

            This usually means the folder is protected by Files & Folders, Full Disk Access, sandboxing, or iCloud Drive settings.
            You can try a different save location in Clip Paste's settings or adjust your macOS privacy settings.
            """
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
