import SwiftUI

public struct AlertsView: View {
    @Environment(AppState.self) private var appState

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Events")
                    .font(.headline)
                Spacer()
                if !appState.alertEngine.events.isEmpty {
                    Button("Clear All") {
                        appState.alertEngine.clearAll()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if appState.alertEngine.events.isEmpty {
                ContentUnavailableView {
                    Label("No Events", systemImage: "bell.slash")
                } description: {
                    Text("Port activity will appear here")
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.alertEngine.events) { event in
                            AlertEventRow(event: event)
                                .padding(.horizontal, 12)
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }
        }
        .onAppear {
            appState.alertEngine.markAllRead()
        }
    }
}

private struct AlertEventRow: View {
    let event: AlertEvent

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .fontWeight(.medium)
                    Spacer()
                    Text(event.timestamp, format: .dateTime.hour().minute().second())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .opacity(event.isRead ? 0.7 : 1.0)
    }

    private var dotColor: Color {
        switch event.type {
        case .opened: .green
        case .closed: .red
        case .changed: .yellow
        }
    }

    private var title: String {
        switch event.type {
        case .opened:
            "Port \(event.entry.port) opened"
        case .closed:
            "Port \(event.entry.port) closed"
        case .changed:
            "Port \(event.entry.port) changed"
        }
    }

    private var subtitle: String {
        switch event.type {
        case .opened:
            "\(event.entry.processName) (PID \(event.entry.pid)) on \(event.entry.address)"
        case .closed:
            "\(event.entry.processName) (PID \(event.entry.pid))"
        case .changed(let prevProcess, let prevPID):
            "\(prevProcess) (PID \(prevPID)) -> \(event.entry.processName) (PID \(event.entry.pid))"
        }
    }
}
