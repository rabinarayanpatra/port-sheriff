import Testing
@testable import PortSheriffKit
import Foundation

@Suite("AlertEngine")
struct AlertEngineTests {

    private func makeEntry(
        port: UInt16 = 3000,
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

    @Test("blocklisted port produces high priority alert")
    func blocklist() {
        let rules = [
            AlertRule(name: "Block 6666", type: .blocklist, matcher: .port(6666))
        ]
        let entry = makeEntry(port: 6666)
        let result = AlertEngine.evaluate(entry: entry, rules: rules, securityMode: false)
        #expect(result == .high)
    }

    @Test("whitelisted port produces nil (silent)")
    func whitelist() {
        let rules = [
            AlertRule(name: "Allow 3000-3999", type: .whitelist, matcher: .portRange(from: 3000, to: 3999))
        ]
        let entry = makeEntry(port: 3000)
        let result = AlertEngine.evaluate(entry: entry, rules: rules, securityMode: true)
        #expect(result == nil)
    }

    @Test("unknown port with security mode ON produces medium priority")
    func unknownSecurityOn() {
        let rules: [AlertRule] = []
        let entry = makeEntry(port: 9999)
        let result = AlertEngine.evaluate(entry: entry, rules: rules, securityMode: true)
        #expect(result == .medium)
    }

    @Test("unknown port with security mode OFF produces info")
    func unknownSecurityOff() {
        let rules: [AlertRule] = []
        let entry = makeEntry(port: 9999)
        let result = AlertEngine.evaluate(entry: entry, rules: rules, securityMode: false)
        #expect(result == .info)
    }

    @Test("blocklist takes precedence over whitelist")
    func blocklistPrecedence() {
        let rules = [
            AlertRule(name: "Allow range", type: .whitelist, matcher: .portRange(from: 3000, to: 4000)),
            AlertRule(name: "Block 3500", type: .blocklist, matcher: .port(3500)),
        ]
        let entry = makeEntry(port: 3500)
        let result = AlertEngine.evaluate(entry: entry, rules: rules, securityMode: false)
        #expect(result == .high)
    }

    @Test("disabled rule is ignored")
    func disabledRule() {
        let rules = [
            AlertRule(name: "Block 6666", type: .blocklist, matcher: .port(6666), enabled: false)
        ]
        let entry = makeEntry(port: 6666)
        let result = AlertEngine.evaluate(entry: entry, rules: rules, securityMode: false)
        #expect(result == .info) // falls through to default
    }

    @Test("process name matcher works case-insensitively")
    func processNameMatch() {
        let rules = [
            AlertRule(name: "Block crypto miners", type: .blocklist, matcher: .processName("xmrig"))
        ]
        let entry = makeEntry(processName: "XMRig")
        let result = AlertEngine.evaluate(entry: entry, rules: rules, securityMode: false)
        #expect(result == .high)
    }

    @Test("changed port always produces high priority")
    func changedPort() {
        let priority = AlertEngine.evaluateChange()
        #expect(priority == .high)
    }
}
