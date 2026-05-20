import SwiftUI

struct PortRowView: View {
    let entry: PortEntry
    let onKill: (Int32, Bool) -> Void

    @State private var isExpanded = false
    @State private var killState: KillState = .idle
    @State private var showSystemKillConfirm = false
    @State private var pendingForce = false

    enum KillState {
        case idle
        case terminating
        case waitingForForce
    }

    private var isSystem: Bool {
        ProcessManager.isSystemProcess(pid: entry.pid, name: entry.processName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(entry.port))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    if isSystem {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .help("System process — kill with caution")
                    }
                    Text(entry.processName)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(String(entry.pid))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)

                killButton
                    .frame(width: 80)
            }
            .contentShape(Rectangle())
            .onTapGesture { isExpanded.toggle() }

            if isExpanded {
                expandedDetail
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog(
            "Kill system process \(entry.processName) (PID \(entry.pid))?",
            isPresented: $showSystemKillConfirm,
            titleVisibility: .visible
        ) {
            Button("Kill anyway", role: .destructive) {
                performKill(force: pendingForce)
            }
            Button("Cancel", role: .cancel) {
                killState = .idle
            }
        } message: {
            Text("This is a macOS system process. Killing it may destabilize the OS or log you out.")
        }
    }

    @ViewBuilder
    private var killButton: some View {
        switch killState {
        case .idle:
            Button("Kill") {
                pendingForce = false
                if isSystem {
                    showSystemKillConfirm = true
                } else {
                    performKill(force: false)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(isSystem ? .orange : nil)

        case .terminating:
            ProgressView()
                .controlSize(.small)

        case .waitingForForce:
            Button("Force") {
                pendingForce = true
                if isSystem {
                    showSystemKillConfirm = true
                } else {
                    performKill(force: true)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.small)
        }
    }

    private func performKill(force: Bool) {
        killState = .terminating
        onKill(entry.pid, force)
        Task {
            try? await Task.sleep(for: .seconds(3))
            if ProcessManager.isAlive(pid: entry.pid) {
                killState = .waitingForForce
            } else {
                killState = .idle
            }
        }
    }

    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 4) {
            detailRow("Address", entry.address)
            detailRow("Command", entry.command)
            detailRow("User", entry.user)
            detailRow("Since", entry.firstSeen.formatted(.dateTime.hour().minute().second()))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.leading, 12)
        .padding(.top, 4)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .frame(width: 60, alignment: .trailing)
                .fontWeight(.medium)
            Text(value)
                .textSelection(.enabled)
        }
    }
}
