import Foundation
import Observation

@MainActor
@Observable
public final class SettingsStore {
    private static let defaults = UserDefaults.standard

    private enum Keys {
        static let pollInterval = "pollInterval"
        static let launchAtLogin = "launchAtLogin"
        static let soundEnabled = "soundEnabled"
        static let securityMode = "securityMode"
        static let alertRules = "alertRules"
    }

    public var pollInterval: Double {
        didSet { Self.defaults.set(pollInterval, forKey: Keys.pollInterval) }
    }

    public var launchAtLogin: Bool {
        didSet { Self.defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    public var soundEnabled: Bool {
        didSet { Self.defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    public var securityMode: Bool {
        didSet { Self.defaults.set(securityMode, forKey: Keys.securityMode) }
    }

    public var alertRules: [AlertRule] {
        didSet { saveRules() }
    }

    public init() {
        let d = Self.defaults
        self.pollInterval = d.object(forKey: Keys.pollInterval) as? Double ?? 5.0
        self.launchAtLogin = d.bool(forKey: Keys.launchAtLogin)
        self.soundEnabled = d.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.securityMode = d.object(forKey: Keys.securityMode) as? Bool ?? true
        self.alertRules = Self.loadRules()
    }

    private func saveRules() {
        if let data = try? JSONEncoder().encode(alertRules) {
            Self.defaults.set(data, forKey: Keys.alertRules)
        }
    }

    private static func loadRules() -> [AlertRule] {
        guard let data = defaults.data(forKey: Keys.alertRules),
              let rules = try? JSONDecoder().decode([AlertRule].self, from: data)
        else { return Self.defaultRules }
        return rules
    }

    public static let defaultRules: [AlertRule] = [
        AlertRule(
            name: "Common dev ports",
            type: .whitelist,
            matcher: .portRange(from: 3000, to: 3999),
            enabled: true
        ),
        AlertRule(
            name: "Vite/HMR",
            type: .whitelist,
            matcher: .port(5173),
            enabled: true
        ),
        AlertRule(
            name: "Common HTTP dev",
            type: .whitelist,
            matcher: .port(8080),
            enabled: true
        ),
    ]
}
