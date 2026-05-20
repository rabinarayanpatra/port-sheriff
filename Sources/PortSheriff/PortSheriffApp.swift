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
}
