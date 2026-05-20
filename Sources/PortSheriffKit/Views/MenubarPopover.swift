import SwiftUI

public struct MenubarPopover: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = .ports
    @State private var showSettings = false

    enum Tab: String, CaseIterable {
        case ports = "Ports"
        case alerts = "Alerts"
        case rules = "Rules"
    }

    public init() {}

    private var unreadCount: Int {
        appState.alertEngine.events.filter { !$0.isRead }.count
    }

    private func label(for tab: Tab) -> String {
        if tab == .alerts && unreadCount > 0 {
            return "Alerts (\(unreadCount))"
        }
        return tab.rawValue
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(label(for: tab)).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .help("Settings")

                Button {
                    appState.stop()
                    UserDefaults.standard.synchronize()
                    exit(0)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("q", modifiers: .command)
                .help("Quit Port Sheriff (⌘Q)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .ports:
                    PortListView()
                case .alerts:
                    AlertsView()
                case .rules:
                    RulesView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 420, height: 480)
        .task {
            appState.start()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(appState)
                .frame(width: 350, height: 300)
        }
    }
}
