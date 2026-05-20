import SwiftUI
import PortSheriffKit

@main
struct PortSheriffApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenubarPopover()
                .environment(appState)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: appState.hasAlerts ? "shield.fill" : "shield")
                if appState.hasAlerts {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
    }
}

/// Dummy view until real MenubarPopover is built.
struct MenubarPopover: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack {
            Text("Port Sheriff")
                .font(.headline)
            Text("\(appState.scanner.ports.count) ports active")
            Button("Scan Now") {
                appState.scanNow()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 300)
        .task {
            appState.start()
        }
    }
}
