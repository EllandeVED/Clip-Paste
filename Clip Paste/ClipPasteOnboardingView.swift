import SwiftUI

struct ClipPasteOnboardingView: View {
    @Binding var isPresented: Bool

    @State private var isDefaultSaveEnabled = Preferences.isDefaultSaveEnabled
    @State private var selectedSaveLocation = Preferences.saveLocation
    @State private var isImageEnabled = Preferences.isImageBehaviorEnabled
    @State private var isTextEnabled = Preferences.isTextBehaviorEnabled

    var body: some View {
        VStack(spacing: 0) {
            // Header with icon and title
            VStack(spacing: 12) {
                if let icon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 72, height: 72)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                }

                Text("Welcome to Clip Paste")
                    .font(.largeTitle.bold())

                Text("Turn clipboard images and text into files with a single shortcut.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            Divider()
                .padding(.top, 16)

            // Settings form
            Form {
                Section("Default Save (when not in Finder)") {
                    Toggle("Use a default save folder", isOn: $isDefaultSaveEnabled)

                    Picker("Save files to:", selection: $selectedSaveLocation) {
                        ForEach(SaveLocation.allCases) { location in
                            Text(location.displayName).tag(location)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!isDefaultSaveEnabled)

                    Text("When Finder is not frontmost, files will be created here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Features") {
                    Toggle("Create image files from clipboard images", isOn: $isImageEnabled)
                    Toggle("Create text files from clipboard text", isOn: $isTextEnabled)

                    Text("You can change these options later in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 520)

            Divider()

            // Bottom buttons
            HStack {
                Spacer()
                Button("Continue") {
                    persistSettingsAndFinish()
                }
                .keyboardShortcut(.defaultAction)
                .padding(.trailing, 16)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .frame(minWidth: 640, idealWidth: 640, minHeight: 520, idealHeight: 520)
        .padding(.bottom, 4)
    }

    private func persistSettingsAndFinish() {
        Preferences.isDefaultSaveEnabled = isDefaultSaveEnabled
        Preferences.saveLocation = selectedSaveLocation
        Preferences.isImageBehaviorEnabled = isImageEnabled
        Preferences.isTextBehaviorEnabled = isTextEnabled

        // Dismiss the onboarding view; AppDelegate will treat this as
        // “onboarding has been seen” (whether via Continue or window close).
        isPresented = false
    }
}
