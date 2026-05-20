import SwiftUI

struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State var name: String
    @State var ruleType: AlertRuleType
    @State var matcherType: MatcherType = .port
    @State var portValue: String
    @State var portRangeFrom: String
    @State var portRangeTo: String
    @State var processNameValue: String

    let onSave: (AlertRule) -> Void

    enum MatcherType: String, CaseIterable {
        case port = "Port"
        case portRange = "Port Range"
        case processName = "Process Name"
    }

    /// Create editor for a new rule.
    init(onSave: @escaping (AlertRule) -> Void) {
        self._name = State(initialValue: "")
        self._ruleType = State(initialValue: .whitelist)
        self._portValue = State(initialValue: "")
        self._portRangeFrom = State(initialValue: "")
        self._portRangeTo = State(initialValue: "")
        self._processNameValue = State(initialValue: "")
        self.onSave = onSave
    }

    /// Create editor for an existing rule.
    init(rule: AlertRule, onSave: @escaping (AlertRule) -> Void) {
        self._name = State(initialValue: rule.name)
        self._ruleType = State(initialValue: rule.type)
        self.onSave = onSave

        switch rule.matcher {
        case .port(let p):
            self._matcherType = State(initialValue: .port)
            self._portValue = State(initialValue: "\(p)")
            self._portRangeFrom = State(initialValue: "")
            self._portRangeTo = State(initialValue: "")
            self._processNameValue = State(initialValue: "")
        case .portRange(let from, let to):
            self._matcherType = State(initialValue: .portRange)
            self._portValue = State(initialValue: "")
            self._portRangeFrom = State(initialValue: "\(from)")
            self._portRangeTo = State(initialValue: "\(to)")
            self._processNameValue = State(initialValue: "")
        case .processName(let name):
            self._matcherType = State(initialValue: .processName)
            self._portValue = State(initialValue: "")
            self._portRangeFrom = State(initialValue: "")
            self._portRangeTo = State(initialValue: "")
            self._processNameValue = State(initialValue: name)
        case .compound(let p, let name):
            self._matcherType = State(initialValue: .port)
            self._portValue = State(initialValue: "\(p)")
            self._portRangeFrom = State(initialValue: "")
            self._portRangeTo = State(initialValue: "")
            self._processNameValue = State(initialValue: name)
        }
    }

    var body: some View {
        Form {
            TextField("Rule Name", text: $name)

            Picker("Type", selection: $ruleType) {
                Text("Whitelist (allow)").tag(AlertRuleType.whitelist)
                Text("Blocklist (alert)").tag(AlertRuleType.blocklist)
            }

            Picker("Match By", selection: $matcherType) {
                ForEach(MatcherType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            switch matcherType {
            case .port:
                TextField("Port (e.g. 3000)", text: $portValue)
            case .portRange:
                HStack {
                    TextField("From", text: $portRangeFrom)
                    Text("-")
                    TextField("To", text: $portRangeTo)
                }
            case .processName:
                TextField("Process name (e.g. node)", text: $processNameValue)
            }
        }
        .formStyle(.grouped)
        .frame(width: 300)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()
        }
    }

    private var isValid: Bool {
        guard !name.isEmpty else { return false }
        switch matcherType {
        case .port:
            return UInt16(portValue) != nil
        case .portRange:
            guard let from = UInt16(portRangeFrom), let to = UInt16(portRangeTo) else { return false }
            return from <= to
        case .processName:
            return !processNameValue.isEmpty
        }
    }

    private func save() {
        let matcher: PortMatcher
        switch matcherType {
        case .port:
            matcher = .port(UInt16(portValue)!)
        case .portRange:
            matcher = .portRange(from: UInt16(portRangeFrom)!, to: UInt16(portRangeTo)!)
        case .processName:
            matcher = .processName(processNameValue)
        }

        let rule = AlertRule(name: name, type: ruleType, matcher: matcher)
        onSave(rule)
        dismiss()
    }
}
