import SwiftUI

public struct PortListView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .port

    enum SortOrder: String, CaseIterable {
        case port = "Port"
        case process = "Process"
        case time = "Time"
    }

    public init() {}

    private var filteredPorts: [PortEntry] {
        var entries = appState.scanner.ports

        if !searchText.isEmpty {
            entries = entries.filter { entry in
                "\(entry.port)".contains(searchText)
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
            // Header
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Filter ports...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(6)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

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
                    Text(searchText.isEmpty
                        ? "No TCP listening ports detected"
                        : "No ports match your filter")
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredPorts) { entry in
                            PortRowView(entry: entry) { pid, force in
                                handleKill(pid: pid, force: force, entry: entry)
                            }
                            .padding(.horizontal, 12)
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                if let lastScan = appState.scanner.lastScanTime {
                    Text("Last scan: \(lastScan, format: .relative(presentation: .numeric))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if appState.scanner.isScanning {
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    private func handleKill(pid: Int32, force: Bool, entry: PortEntry) {
        if ProcessManager.isSystemProcess(pid: pid, name: entry.processName) && !force {
            // System process warning handled by confirmation in PortRowView
            return
        }
        _ = appState.killProcess(pid: pid, force: force)
    }
}
