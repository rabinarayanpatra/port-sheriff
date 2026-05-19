import Foundation

/// Raw data parsed directly from lsof output, before enrichment.
public struct RawPortInfo: Sendable, Equatable {
    public let port: UInt16
    public let address: String
    public let processName: String
    public let pid: Int32
    public let uid: UInt32

    public init(port: UInt16, address: String, processName: String, pid: Int32, uid: UInt32) {
        self.port = port
        self.address = address
        self.processName = processName
        self.pid = pid
        self.uid = uid
    }
}

/// Enriched port entry with lifecycle metadata.
public struct PortEntry: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let port: UInt16
    public let address: String
    public let processName: String
    public let pid: Int32
    public let user: String
    public let command: String
    public let firstSeen: Date
    public var lastSeen: Date

    public init(
        id: UUID = UUID(),
        port: UInt16,
        address: String,
        processName: String,
        pid: Int32,
        user: String,
        command: String,
        firstSeen: Date = Date(),
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.port = port
        self.address = address
        self.processName = processName
        self.pid = pid
        self.user = user
        self.command = command
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
    }

    /// Key used to match ports across scans.
    public var matchKey: PortMatchKey {
        PortMatchKey(port: port, address: address)
    }
}

/// Uniquely identifies a listening socket across scans.
public struct PortMatchKey: Hashable, Sendable {
    public let port: UInt16
    public let address: String
}
