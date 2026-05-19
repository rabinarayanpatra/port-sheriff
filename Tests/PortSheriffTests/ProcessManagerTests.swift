import Foundation
import Testing
@testable import PortSheriffKit

@Suite("ProcessManager")
struct ProcessManagerTests {

    @Test("resolves current user UID to username")
    func resolveCurrentUser() {
        let uid = getuid()
        let name = ProcessManager.username(for: uid)
        #expect(!name.isEmpty)
        #expect(name != "\(uid)") // should resolve to a name, not raw UID
    }

    @Test("resolves root UID to root")
    func resolveRoot() {
        let name = ProcessManager.username(for: 0)
        #expect(name == "root")
    }

    @Test("returns UID string for unknown UID")
    func unknownUID() {
        let name = ProcessManager.username(for: 99999)
        // May or may not resolve depending on system, but should not crash
        #expect(!name.isEmpty)
    }

    @Test("gets process path for current process")
    func currentProcessPath() {
        let pid = ProcessInfo.processInfo.processIdentifier
        let path = ProcessManager.processPath(for: pid)
        #expect(path != nil)
        #expect(path?.isEmpty == false)
    }

    @Test("returns nil for nonexistent PID")
    func nonexistentPID() {
        let path = ProcessManager.processPath(for: -1)
        #expect(path == nil)
    }

    @Test("identifies system process correctly")
    func systemProcess() {
        #expect(ProcessManager.isSystemProcess(pid: 1, name: "launchd"))
        #expect(ProcessManager.isSystemProcess(pid: 500, name: "mDNSResponder"))
        #expect(!ProcessManager.isSystemProcess(pid: 50000, name: "node"))
    }

    @Test("detects if process is owned by current user")
    func processOwnership() {
        let pid = ProcessInfo.processInfo.processIdentifier
        // Current process is owned by current user
        #expect(ProcessManager.isOwnedByCurrentUser(pid: pid))
        // PID 1 (launchd) is owned by root
        #expect(!ProcessManager.isOwnedByCurrentUser(pid: 1))
    }
}
