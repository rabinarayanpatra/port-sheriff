import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
public final class AlertEngine {
    public var events: [AlertEvent] = []
    public var hasUnreadAlerts: Bool = false

    /// Set of (port, processName) combos already alerted this session.
    private var alertedCombos: Set<String> = []

    public init() {}

    /// Evaluate a newly opened port against rules. Returns priority, or nil if whitelisted.
    public nonisolated static func evaluate(
        entry: PortEntry,
        rules: [AlertRule],
        securityMode: Bool
    ) -> AlertPriority? {
        // Blocklist first (highest precedence)
        for rule in rules where rule.type == .blocklist {
            if rule.matches(port: entry.port, processName: entry.processName) {
                return .high
            }
        }

        // Whitelist second
        for rule in rules where rule.type == .whitelist {
            if rule.matches(port: entry.port, processName: entry.processName) {
                return nil // silent
            }
        }

        // No rule matched
        return securityMode ? .medium : .info
    }

    /// Changed ports are always high priority.
    public nonisolated static func evaluateChange() -> AlertPriority {
        .high
    }

    /// Process a PortDiff and generate alerts.
    public func processDiff(
        _ diff: PortDiff,
        rules: [AlertRule],
        securityMode: Bool,
        soundEnabled: Bool
    ) {
        for entry in diff.opened {
            let comboKey = "\(entry.port):\(entry.processName)"
            guard !alertedCombos.contains(comboKey) else { continue }

            if let priority = Self.evaluate(entry: entry, rules: rules, securityMode: securityMode) {
                let event = AlertEvent(
                    type: .opened,
                    entry: entry,
                    priority: priority
                )
                events.insert(event, at: 0)
                alertedCombos.insert(comboKey)

                if priority == .high || priority == .medium {
                    sendNotification(event: event, soundEnabled: soundEnabled)
                }
            }
        }

        for entry in diff.closed {
            let event = AlertEvent(
                type: .closed,
                entry: entry,
                priority: .info
            )
            events.insert(event, at: 0)
        }

        for change in diff.changed {
            let event = AlertEvent(
                type: .changed(
                    previousProcess: change.old.processName,
                    previousPID: change.old.pid
                ),
                entry: change.new,
                priority: .high
            )
            events.insert(event, at: 0)
            sendNotification(event: event, soundEnabled: soundEnabled)
        }

        hasUnreadAlerts = events.contains { !$0.isRead }
    }

    public func markAllRead() {
        for i in events.indices {
            events[i].isRead = true
        }
        hasUnreadAlerts = false
    }

    public func clearAll() {
        events.removeAll()
        hasUnreadAlerts = false
    }

    public func dismissCombo(port: UInt16, processName: String) {
        alertedCombos.remove("\(port):\(processName)")
    }

    public func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func sendNotification(event: AlertEvent, soundEnabled: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Port Sheriff"

        switch event.type {
        case .opened:
            content.body = "Port \(event.entry.port) opened by \(event.entry.processName) (PID \(event.entry.pid))"
        case .changed(let prevProcess, let prevPID):
            content.body = "Port \(event.entry.port) changed: \(prevProcess) (PID \(prevPID)) -> \(event.entry.processName) (PID \(event.entry.pid))"
        case .closed:
            return // no notification for closed ports
        }

        if soundEnabled {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
