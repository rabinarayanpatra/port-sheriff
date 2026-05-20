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

    public var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                            if tab == .alerts && appState.alertEngine.hasUnreadAlerts {
                                let unreadCount = appState.alertEngine.events.filter { !$0.isRead }.count
                                Text(String(unreadCount))
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .background(.red)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
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
