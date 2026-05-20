import SwiftUI

public struct PortListView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .port
    @State private var hideSystem = true

    enum SortOrder: String, CaseIterable {
        case port = "Port"
        case process = "Process"
        case time = "Time"
    }

    public init() {}

    private var allPorts: [PortEntry] {
        appState.scanner.ports
    }

    private var systemPortCount: Int {
        allPorts.filter { ProcessManager.isSystemProcess(pid: $0.pid, name: $0.processName) }.count
    }

    private var filteredPorts: [PortEntry] {
        var entries = allPorts

        if hideSystem {
            entries = entries.filter { !ProcessManager.isSystemProcess(pid: $0.pid, name: $0.processName) }
        }

        if !searchText.isEmpty {
            entries = entries.filter { entry in
                String(entry.port).contains(searchText)
                    || entry.processName.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .port:
            entries.sort { $0.port < $1.port }
        case .process:
            entries.sort { $0.processName.lowercased() < $1.processName.lowercased() }
        case .time:
            entries.sort { $0.firstSeen > $1.firstSeen }
        }

        return entries
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search row
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Filter ports...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(6)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Toggle(isOn: $hideSystem) {
                    Image(systemName: hideSystem ? "lock.fill" : "lock.open")
                        .help(hideSystem ? "Showing user processes only" : "Showing all processes")
                }
                .toggleStyle(.button)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Sort row
            HStack(spacing: 6) {
                Text("Sort")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            // Column headers
            HStack {
                Text("PORT").frame(width: 60, alignment: .leading)
                Text("PROCESS").frame(maxWidth: .infinity, alignment: .leading)
                Text("PID").frame(width: 60, alignment: .trailing)
                Text("").frame(width: 80)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            // Port list
            if filteredPorts.isEmpty {
                ContentUnavailableView {
                    Label("No Ports", systemImage: "network.slash")
                } description: {
                    Text(emptyStateMessage)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredPorts) { entry in
                            PortRowView(entry: entry) { pid, force in
                                _ = appState.killProcess(pid: pid, force: force)
                            }
                            .padding(.horizontal, 12)
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack(spacing: 8) {
                if let lastScan = appState.scanner.lastScanTime {
                    Text("Last scan: \(lastScan, format: .relative(presentation: .numeric))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if appState.scanner.isScanning {
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if hideSystem && systemPortCount > 0 {
                    Text("• \(systemPortCount) system hidden")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if let error = appState.scanner.scanError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()

                Button {
                    appState.scanNow()
                } label: {
                    Label("Scan Now", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "No ports match your filter"
        }
        if hideSystem && systemPortCount > 0 {
            return "Only system ports listening. Toggle the lock to show them."
        }
        return "No TCP listening ports detected"
    }
}
