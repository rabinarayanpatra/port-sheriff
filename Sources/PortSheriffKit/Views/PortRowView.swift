import SwiftUI

struct PortRowView: View {
    let entry: PortEntry
    let onKill: (Int32, Bool) -> Void

    @State private var isExpanded = false
    @State private var killState: KillState = .idle

    enum KillState {
        case idle
        case terminating
        case waitingForForce
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(entry.port)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .frame(width: 60, alignment: .leading)

                Text(entry.processName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                Text("\(entry.pid)")
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
    }

    @ViewBuilder
    private var killButton: some View {
        switch killState {
        case .idle:
            Button("Kill") {
                killState = .terminating
                onKill(entry.pid, false)
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    if ProcessManager.isAlive(pid: entry.pid) {
                        killState = .waitingForForce
                    } else {
                        killState = .idle
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

        case .terminating:
            ProgressView()
                .controlSize(.small)

        case .waitingForForce:
            Button("Force") {
                onKill(entry.pid, true)
                killState = .idle
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.small)
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
