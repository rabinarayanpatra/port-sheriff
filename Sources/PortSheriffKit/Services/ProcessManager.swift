import Foundation
import Darwin
import Darwin.sys.proc_info

/// Handles process inspection and termination.
public enum ProcessManager {

    /// Resolve a numeric UID to a username string.
    public static func username(for uid: uid_t) -> String {
        if let pw = getpwuid(uid) {
            return String(cString: pw.pointee.pw_name)
        }
        return "\(uid)"
    }

    /// Get the full executable path for a PID using proc_pidpath.
    public static func processPath(for pid: Int32) -> String? {
        // PROC_PIDPATHINFO_MAXSIZE = 4 * MAXPATHLEN = 4 * 1024 on Darwin.
        // The macro is unavailable to Swift, so we use the literal value.
        let bufferSize = 4 * 1024
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        let length = proc_pidpath(pid, buffer, UInt32(bufferSize))
        guard length > 0 else { return nil }
        return String(cString: buffer)
    }

    /// Check if a PID belongs to a system process.
    public static func isSystemProcess(pid: Int32, name: String) -> Bool {
        let systemNames: Set<String> = [
            "launchd", "kernel_task", "mDNSResponder", "WindowServer",
            "loginwindow", "SystemUIServer", "dock", "Finder",
            "coreservicesd", "opendirectoryd", "syslogd",
        ]
        return pid < 1000 || systemNames.contains(name)
    }

    /// Check if process is owned by current user.
    public static func isOwnedByCurrentUser(pid: Int32) -> Bool {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size)
        guard result == size else { return false }
        return info.pbi_uid == getuid()
    }

    public enum KillResult: Sendable {
        case success
        case processNotFound
        case permissionDenied
        case failed(String)
    }

    /// Send SIGTERM to a process.
    public static func terminate(pid: Int32) -> KillResult {
        sendSignal(pid: pid, signal: SIGTERM)
    }

    /// Send SIGKILL to a process.
    public static func forceKill(pid: Int32) -> KillResult {
        sendSignal(pid: pid, signal: SIGKILL)
    }

    /// Check if a process is still running.
    public static func isAlive(pid: Int32) -> Bool {
        kill(pid, 0) == 0
    }

    private static func sendSignal(pid: Int32, signal: Int32) -> KillResult {
        let result = kill(pid, signal)
        if result == 0 {
            return .success
        }
        switch errno {
        case ESRCH:
            return .processNotFound
        case EPERM:
            return .permissionDenied
        default:
            return .failed(String(cString: strerror(errno)))
        }
    }
}
