import SwiftUI

public struct RulesView: View {
    @Environment(AppState.self) private var appState
    @State private var showEditor = false

    public init() {}

    public var body: some View {
        @Bindable var settings = appState.settings

        VStack(spacing: 0) {
            HStack {
                Text("Rules")
                    .font(.headline)
                Spacer()
                Button {
                    showEditor = true
                } label: {
                    Label("Add Rule", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if settings.alertRules.isEmpty {
                ContentUnavailableView {
                    Label("No Rules", systemImage: "list.bullet.rectangle")
                } description: {
                    Text("Add rules to control which ports trigger alerts")
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(settings.alertRules.enumerated()), id: \.element.id) { index, rule in
                            RuleRow(rule: rule) { enabled in
                                settings.alertRules[index].enabled = enabled
                            } onDelete: {
                                settings.alertRules.remove(at: index)
                            }
                            .padding(.horizontal, 12)
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            RuleEditorView { newRule in
                appState.settings.alertRules.append(newRule)
            }
        }
    }
}

private struct RuleRow: View {
    let rule: AlertRule
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { onToggle($0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(rule.name)
                        .fontWeight(.medium)
                    Text(rule.type == .whitelist ? "ALLOW" : "BLOCK")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(rule.type == .whitelist ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .foregroundStyle(rule.type == .whitelist ? .green : .red)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }

                Text(matcherDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 6)
        .opacity(rule.enabled ? 1.0 : 0.5)
    }

    private var matcherDescription: String {
        switch rule.matcher {
        case .port(let p):
            "Port \(p)"
        case .portRange(let from, let to):
            "Ports \(from)-\(to)"
        case .processName(let name):
            "Process: \(name)"
        case .compound(let p, let name):
            "Port \(p) + Process: \(name)"
        }
    }
}
