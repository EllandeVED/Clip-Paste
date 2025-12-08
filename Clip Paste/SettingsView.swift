import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

enum SettingsTab: Hashable {
    case general
    case image
    case text
}

struct SettingsView: View {
    @State private var isImageEnabled: Bool = Preferences.isImageBehaviorEnabled
    @State private var isTextEnabled: Bool = Preferences.isTextBehaviorEnabled
    @State private var selectedSaveLocation: SaveLocation = Preferences.saveLocation
    @State private var isDefaultSaveEnabled: Bool = Preferences.isDefaultSaveEnabled
    @State private var imageTemplate: String = Preferences.imageFilenameTemplate
    @State private var textTemplate: String = Preferences.textFilenameTemplate
    @State private var selectedTab: SettingsTab = .general

    @State private var imageCounterValue: Int = Preferences.imageCounter
    @State private var textCounterValue: Int = Preferences.textCounter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Tab", selection: $selectedTab) {
                Text("General").tag(SettingsTab.general)
                Text("Image").tag(SettingsTab.image)
                Text("Text").tag(SettingsTab.text)
            }
            .pickerStyle(.segmented)
            .tint(.blue)

            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsTab(
                        selectedSaveLocation: $selectedSaveLocation,
                        isDefaultSaveEnabled: $isDefaultSaveEnabled
                    )
                case .image:
                    ImageSettingsTab(
                        isImageEnabled: $isImageEnabled,
                        imageTemplate: $imageTemplate,
                        imageCounter: $imageCounterValue
                    )
                case .text:
                    TextSettingsTab(
                        isTextEnabled: $isTextEnabled,
                        textTemplate: $textTemplate,
                        textCounter: $textCounterValue
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(20)
        .onChange(of: isImageEnabled) { newValue in
            Preferences.isImageBehaviorEnabled = newValue
        }
        .onChange(of: isTextEnabled) { newValue in
            Preferences.isTextBehaviorEnabled = newValue
        }
        .onChange(of: selectedSaveLocation) { newValue in
            Preferences.saveLocation = newValue
        }
        .onChange(of: isDefaultSaveEnabled) { newValue in
            Preferences.isDefaultSaveEnabled = newValue
        }
        .onChange(of: imageTemplate) { newValue in
            Preferences.imageFilenameTemplate = newValue
        }
        .onChange(of: textTemplate) { newValue in
            Preferences.textFilenameTemplate = newValue
        }
        .onAppear {
            imageCounterValue = Preferences.imageCounter
            textCounterValue = Preferences.textCounter
        }
    }
}

struct GeneralSettingsTab: View {
    @Binding var selectedSaveLocation: SaveLocation
    @Binding var isDefaultSaveEnabled: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Global Shortcut").font(.headline)) {
                    HStack {
                        Text("Shortcut:")
                        KeyboardShortcuts.Recorder(for: .smartPaste)
                    }
                    Text("Use this shortcut in Finder to trigger smart paste.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox(label: Text("Default Save Location").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Use a default save folder when Finder is not frontmost", isOn: $isDefaultSaveEnabled)

                        VStack(alignment: .leading, spacing: 4) {
                            Picker("Save files to:", selection: $selectedSaveLocation) {
                                ForEach(SaveLocation.allCases) { location in
                                    Text(location.displayName).tag(location)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("This were the file will be saved when executing the app outside Finder.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .disabled(!isDefaultSaveEnabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox(label: Text("General").font(.headline)) {
                    LaunchAtLogin.Toggle("Open at login")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox(label: Text("Updates").font(.headline)) {
                    HStack {
                        Text("Check for a new version of Clip Paste on GitHub.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Check for Updates…") {
                            CPUpdateChecker.shared.checkNow()
                        }
                        .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}

struct ImageSettingsTab: View {
    @Binding var isImageEnabled: Bool
    @Binding var imageTemplate: String
    @Binding var imageCounter: Int

    private var imageTemplateContainsVariable: Bool {
        imageTemplate.contains("{date}") ||
        imageTemplate.contains("{time}") ||
        imageTemplate.contains("{datetime}") ||
        imageTemplate.contains("{weekday}") ||
        imageTemplate.contains("{counter}") ||
        imageTemplate.contains("{name}")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Image Behaviour").font(.headline)) {
                    Toggle("Create image file when clipboard contains an image", isOn: $isImageEnabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 20) {
                    GroupBox(label: Text("Image Filename Template").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("""
You can use these variables in the image filename:
- {date}      → 2025-12-07
- {time}      → 22.41.05
- {datetime}  → 2025-12-07 22.41.05
- {weekday}   → Sunday
- {counter}   → 1, 2, 3...
- {name}      → image name from the clipboard (if available)

The .png extension is added automatically.
""")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("Example: Image {name} {date} at {time}")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                TextField("Image filename template", text: $imageTemplate)
                                    .frame(maxWidth: .infinity)
                                    .textFieldStyle(.roundedBorder)
                                Text(".png")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                            if !imageTemplateContainsVariable {
                                HStack(spacing: 4) {
                                    Text("⚠️")
                                    Text("No variables used: this may overwrite files with the same name.")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    GroupBox(label: Text("Counter").font(.headline)) {
                        HStack {
                            Text("Current value:")
                            Text("\(imageCounter)")
                                .monospacedDigit()
                            Spacer()
                            Button("Reset to zero") {
                                imageCounter = 0
                                Preferences.imageCounter = 0
                            }
                            .controlSize(.small)
                        }
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .disabled(!isImageEnabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}

struct TextSettingsTab: View {
    @Binding var isTextEnabled: Bool
    @Binding var textTemplate: String
    @Binding var textCounter: Int

    private var textTemplateContainsVariable: Bool {
        textTemplate.contains("{date}") ||
        textTemplate.contains("{time}") ||
        textTemplate.contains("{datetime}") ||
        textTemplate.contains("{weekday}") ||
        textTemplate.contains("{counter}") ||
        textTemplate.contains("{firstWords}")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Text Behaviour").font(.headline)) {
                    Toggle("Create text file when clipboard contains text", isOn: $isTextEnabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 20) {
                    GroupBox(label: Text("Text Filename Template").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("""
You can use these variables in the text filename:
- {date}      → 2025-12-07
- {time}      → 22.41.05
- {datetime}  → 2025-12-07 22.41.05
- {weekday}   → Sunday
- {counter}   → 1, 2, 3...
- {firstWords} → first words of the clipboard text

The .txt extension is added automatically.
""")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("Example: Note {date} - {firstWords}")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                TextField("Text filename template", text: $textTemplate)
                                    .frame(maxWidth: .infinity)
                                    .textFieldStyle(.roundedBorder)
                                Text(".txt")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                            if !textTemplateContainsVariable {
                                HStack(spacing: 4) {
                                    Text("⚠️")
                                    Text("No variables used: this may overwrite files with the same name.")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    GroupBox(label: Text("Counter").font(.headline)) {
                        HStack {
                            Text("Current value:")
                            Text("\(textCounter)")
                                .monospacedDigit()
                            Spacer()
                            Button("Reset to zero") {
                                textCounter = 0
                                Preferences.textCounter = 0
                            }
                            .controlSize(.small)
                        }
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .disabled(!isTextEnabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}


///#Preview {SettingsView()}
