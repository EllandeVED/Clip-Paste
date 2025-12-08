import Foundation

enum SaveLocation: String, CaseIterable, Identifiable {
    case desktop
    case downloads
    case pictures

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .desktop:
            return "Desktop"
        case .downloads:
            return "Downloads"
        case .pictures:
            return "Pictures"
        }
    }
}

enum BehaviorKey: String {
    case imageEnabled
    case textEnabled
    case saveLocation
    case imageFilenameTemplate
    case textFilenameTemplate
    case imageCounter
    case textCounter
}

struct Preferences {
    private static let defaults = UserDefaults.standard

    static var isImageBehaviorEnabled: Bool {
        get { defaults.bool(forKey: BehaviorKey.imageEnabled.rawValue) }
        set { defaults.set(newValue, forKey: BehaviorKey.imageEnabled.rawValue) }
    }

    static var isTextBehaviorEnabled: Bool {
        get { defaults.bool(forKey: BehaviorKey.textEnabled.rawValue) }
        set { defaults.set(newValue, forKey: BehaviorKey.textEnabled.rawValue) }
    }

    static var saveLocation: SaveLocation {
        get {
            if let raw = defaults.string(forKey: BehaviorKey.saveLocation.rawValue),
               let loc = SaveLocation(rawValue: raw) {
                return loc
            }
            return .desktop
        }
        set {
            defaults.set(newValue.rawValue, forKey: BehaviorKey.saveLocation.rawValue)
        }
    }

    static var imageFilenameTemplate: String {
        get {
            defaults.string(forKey: BehaviorKey.imageFilenameTemplate.rawValue)
            ?? "Image {date} at {time}"
        }
        set {
            defaults.set(newValue, forKey: BehaviorKey.imageFilenameTemplate.rawValue)
        }
    }

    static var textFilenameTemplate: String {
        get {
            defaults.string(forKey: BehaviorKey.textFilenameTemplate.rawValue)
            ?? "Note {date} at {time}"
        }
        set {
            defaults.set(newValue, forKey: BehaviorKey.textFilenameTemplate.rawValue)
        }
    }

    static var imageCounter: Int {
        get { defaults.integer(forKey: BehaviorKey.imageCounter.rawValue) }
        set { defaults.set(newValue, forKey: BehaviorKey.imageCounter.rawValue) }
    }

    static var textCounter: Int {
        get { defaults.integer(forKey: BehaviorKey.textCounter.rawValue) }
        set { defaults.set(newValue, forKey: BehaviorKey.textCounter.rawValue) }
    }

    static func nextImageCounter() -> Int {
        let current = defaults.integer(forKey: BehaviorKey.imageCounter.rawValue)
        let next = current + 1
        defaults.set(next, forKey: BehaviorKey.imageCounter.rawValue)
        return next
    }

    static func nextTextCounter() -> Int {
        let current = defaults.integer(forKey: BehaviorKey.textCounter.rawValue)
        let next = current + 1
        defaults.set(next, forKey: BehaviorKey.textCounter.rawValue)
        return next
    }
}
