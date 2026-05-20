import Foundation
import Observation

@MainActor
@Observable
public final class PortScanner {
    public var ports: [PortEntry] = []
    public var lastScanTime: Date?
    public var scanError: String?
    public var isScanning: Bool = false

    private var pollingTask: Task<Void, Never>?
    private var noChangeCount: Int = 0

    public init() {}

    /// Run a single scan, update state, return the diff.
    public func scan() async -> PortDiff? {
        isScanning = true
        defer { isScanning = false }
        scanError = nil

        let output: String
        do {
            output = try await runLsof()
        } catch {
            scanError = "Scan failed: \(error.localizedDescription)"
            return nil
        }

        let rawEntries = LsofParser.parse(output: output)
        let newEntries = await enrichEntries(rawEntries)

        // Merge: preserve firstSeen for existing ports
        let merged = mergeEntries(existing: ports, incoming: newEntries)
        let diff = DiffEngine.computeDiff(previous: ports, current: merged)

        ports = merged.sorted { $0.port < $1.port }
        lastScanTime = Date()

        if diff.isEmpty {
            noChangeCount += 1
        } else {
            noChangeCount = 0
        }

        return diff
    }

    /// Start hybrid polling loop.
    public func startPolling(interval: @escaping () -> Double) {
        stopPolling()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                _ = await self.scan()
                let baseInterval = interval()
                let effectiveInterval = self.noChangeCount >= 10 ? baseInterval * 2 : baseInterval
                try? await Task.sleep(for: .seconds(effectiveInterval))
            }
        }
    }

    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    /// Trigger an immediate re-scan (e.g. after a kill or popover open).
    public func rescanSoon() {
        Task {
            try? await Task.sleep(for: .seconds(1))
            _ = await scan()
        }
    }

    // MARK: - Private

    private func runLsof() async throws -> String {
        try await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
            process.arguments = ["-iTCP", "-sTCP:LISTEN", "-nP", "-F", "pcnu"]

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            try process.run()
            process.waitUntilExit()

            let data = stdout.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        }.value
    }

    private nonisolated func enrichEntries(_ rawEntries: [RawPortInfo]) async -> [PortEntry] {
        rawEntries.map { raw in
            let user = ProcessManager.username(for: raw.uid)
            let command = ProcessManager.processPath(for: raw.pid) ?? raw.processName

            return PortEntry(
                port: raw.port,
                address: raw.address,
                processName: raw.processName,
                pid: raw.pid,
                user: user,
                command: command
            )
        }
    }

    private func mergeEntries(existing: [PortEntry], incoming: [PortEntry]) -> [PortEntry] {
        let existingByKey = Dictionary(grouping: existing, by: \.matchKey).mapValues { $0.first! }

        return incoming.map { entry in
            if let prev = existingByKey[entry.matchKey] {
                // Preserve firstSeen from previous scan
                var merged = entry
                merged = PortEntry(
                    id: prev.id,
                    port: entry.port,
                    address: entry.address,
                    processName: entry.processName,
                    pid: entry.pid,
                    user: entry.user,
                    command: entry.command,
                    firstSeen: prev.firstSeen,
                    lastSeen: Date()
                )
                return merged
            }
            return entry
        }
    }
}
