import Testing
@testable import PortSheriffKit
import Foundation

@Suite("DiffEngine")
struct DiffEngineTests {

    private func makeEntry(
        port: UInt16,
        address: String = "127.0.0.1",
        processName: String = "node",
        pid: Int32 = 1234
    ) -> PortEntry {
        PortEntry(
            port: port,
            address: address,
            processName: processName,
            pid: pid,
            user: "testuser",
            command: "/usr/bin/\(processName)"
        )
    }

    @Test("detects newly opened ports")
    func opened() {
        let previous: [PortEntry] = []
        let current = [makeEntry(port: 3000)]
        let diff = DiffEngine.computeDiff(previous: previous, current: current)
        #expect(diff.opened.count == 1)
        #expect(diff.opened[0].port == 3000)
        #expect(diff.closed.isEmpty)
        #expect(diff.changed.isEmpty)
    }

    @Test("detects closed ports")
    func closed() {
        let previous = [makeEntry(port: 3000)]
        let current: [PortEntry] = []
        let diff = DiffEngine.computeDiff(previous: previous, current: current)
        #expect(diff.opened.isEmpty)
        #expect(diff.closed.count == 1)
        #expect(diff.closed[0].port == 3000)
        #expect(diff.changed.isEmpty)
    }

    @Test("detects process change on same port")
    func changed() {
        let previous = [makeEntry(port: 3000, processName: "node", pid: 1234)]
        let current = [makeEntry(port: 3000, processName: "python", pid: 5678)]
        let diff = DiffEngine.computeDiff(previous: previous, current: current)
        #expect(diff.opened.isEmpty)
        #expect(diff.closed.isEmpty)
        #expect(diff.changed.count == 1)
        #expect(diff.changed[0].old.processName == "node")
        #expect(diff.changed[0].new.processName == "python")
    }

    @Test("unchanged ports produce empty diff")
    func unchanged() {
        let entry = makeEntry(port: 3000)
        let diff = DiffEngine.computeDiff(previous: [entry], current: [entry])
        #expect(diff.isEmpty)
    }

    @Test("handles mixed changes")
    func mixed() {
        let previous = [
            makeEntry(port: 3000, processName: "node", pid: 100),
            makeEntry(port: 5432, processName: "postgres", pid: 200),
            makeEntry(port: 8080, processName: "java", pid: 300),
        ]
        let current = [
            makeEntry(port: 3000, processName: "node", pid: 100),   // unchanged
            makeEntry(port: 5432, processName: "mysql", pid: 400),  // changed
            makeEntry(port: 9090, processName: "go", pid: 500),     // new
            // 8080 gone = closed
        ]
        let diff = DiffEngine.computeDiff(previous: previous, current: current)
        #expect(diff.opened.count == 1)
        #expect(diff.opened[0].port == 9090)
        #expect(diff.closed.count == 1)
        #expect(diff.closed[0].port == 8080)
        #expect(diff.changed.count == 1)
        #expect(diff.changed[0].old.processName == "postgres")
        #expect(diff.changed[0].new.processName == "mysql")
    }

    @Test("differentiates by address, not just port")
    func differentAddresses() {
        let previous = [makeEntry(port: 3000, address: "127.0.0.1")]
        let current = [makeEntry(port: 3000, address: "::1")]
        let diff = DiffEngine.computeDiff(previous: previous, current: current)
        #expect(diff.opened.count == 1)
        #expect(diff.closed.count == 1)
    }
}
