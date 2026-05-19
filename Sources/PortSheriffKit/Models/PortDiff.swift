import Foundation

/// Result of comparing two port snapshots.
public struct PortDiff: Sendable {
    public let opened: [PortEntry]
    public let closed: [PortEntry]
    public let changed: [PortChange]

    public var isEmpty: Bool {
        opened.isEmpty && closed.isEmpty && changed.isEmpty
    }

    public init(opened: [PortEntry], closed: [PortEntry], changed: [PortChange]) {
        self.opened = opened
        self.closed = closed
        self.changed = changed
    }
}

/// A port where the process changed (same address:port, different PID or process name).
public struct PortChange: Sendable {
    public let old: PortEntry
    public let new: PortEntry

    public init(old: PortEntry, new: PortEntry) {
        self.old = old
        self.new = new
    }
}

/// Computes diffs between port snapshots.
public enum DiffEngine {
    /// Compare previous entries against new raw scan results.
    /// Returns updated entries (with firstSeen preserved) and the diff.
    public static func computeDiff(
        previous: [PortEntry],
        current: [PortEntry]
    ) -> PortDiff {
        let prevByKey = Dictionary(grouping: previous, by: \.matchKey)
            .mapValues { $0.first! }
        let currByKey = Dictionary(grouping: current, by: \.matchKey)
            .mapValues { $0.first! }

        let prevKeys = Set(prevByKey.keys)
        let currKeys = Set(currByKey.keys)

        let openedKeys = currKeys.subtracting(prevKeys)
        let closedKeys = prevKeys.subtracting(currKeys)
        let commonKeys = prevKeys.intersection(currKeys)

        let opened = openedKeys.map { currByKey[$0]! }
        let closed = closedKeys.map { prevByKey[$0]! }

        var changed: [PortChange] = []
        for key in commonKeys {
            let prev = prevByKey[key]!
            let curr = currByKey[key]!
            if prev.pid != curr.pid || prev.processName != curr.processName {
                changed.append(PortChange(old: prev, new: curr))
            }
        }

        return PortDiff(opened: opened, closed: closed, changed: changed)
    }
}
