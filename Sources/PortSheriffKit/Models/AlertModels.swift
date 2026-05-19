import Foundation

public struct AlertRule: Codable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var type: AlertRuleType
    public var matcher: PortMatcher
    public var enabled: Bool

    public init(id: UUID = UUID(), name: String, type: AlertRuleType, matcher: PortMatcher, enabled: Bool = true) {
        self.id = id
        self.name = name
        self.type = type
        self.matcher = matcher
        self.enabled = enabled
    }

    public func matches(port: UInt16, processName: String) -> Bool {
        guard enabled else { return false }
        return matcher.matches(port: port, processName: processName)
    }
}

public enum AlertRuleType: String, Codable, Sendable, CaseIterable {
    case whitelist
    case blocklist
}

public enum PortMatcher: Codable, Sendable {
    case port(UInt16)
    case portRange(from: UInt16, to: UInt16)
    case processName(String)
    case compound(port: UInt16, processName: String)

    public func matches(port: UInt16, processName: String) -> Bool {
        switch self {
        case .port(let p):
            return port == p
        case .portRange(let from, let to):
            return port >= from && port <= to
        case .processName(let name):
            return processName.localizedCaseInsensitiveContains(name)
        case .compound(let p, let name):
            return port == p && processName.localizedCaseInsensitiveContains(name)
        }
    }
}

public enum AlertPriority: Sendable, Equatable {
    case high
    case medium
    case info
}

public struct AlertEvent: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let type: AlertEventType
    public let entry: PortEntry
    public let priority: AlertPriority
    public var isRead: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: AlertEventType,
        entry: PortEntry,
        priority: AlertPriority,
        isRead: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.entry = entry
        self.priority = priority
        self.isRead = isRead
    }
}

public enum AlertEventType: Sendable {
    case opened
    case closed
    case changed(previousProcess: String, previousPID: Int32)
}
