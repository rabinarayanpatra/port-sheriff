import SwiftUI
import ServiceManagement

public struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        @Bindable var settings = appState.settings

        Form {
            Section("Scanning") {
                HStack {
                    Text("Poll interval")
                    Slider(value: $settings.pollInterval, in: 1...30, step: 1)
                    Text("\(Int(settings.pollInterval))s")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 30)
                }
            }

            Section("Notifications") {
                Toggle("Sound", isOn: $settings.soundEnabled)
                Toggle("Security mode (alert on unknown ports)", isOn: $settings.securityMode)
            }

            Section("System") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section {
                HStack {
                    Spacer()
                    Button("Quit Port Sheriff") {
                        quit()
                    }
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func quit() {
        dismiss()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            appState.stop()
            UserDefaults.standard.synchronize()
            NSApp.terminate(nil)
            try? await Task.sleep(for: .milliseconds(500))
            exit(0)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail - user can manually manage in System Settings
            appState.settings.launchAtLogin = !enabled
        }
    }
}
