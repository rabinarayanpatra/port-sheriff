import Foundation
import Observation
import AppKit

@MainActor
@Observable
public final class AppState {
    public let scanner: PortScanner
    public let alertEngine: AlertEngine
    public let settings: SettingsStore

    public var hasAlerts: Bool {
        alertEngine.hasUnreadAlerts
    }

    public init() {
        self.scanner = PortScanner()
        self.alertEngine = AlertEngine()
        self.settings = SettingsStore()
    }

    public func start() {
        alertEngine.requestNotificationPermission()
        scanner.startPolling { [weak self] in
            self?.settings.pollInterval ?? 5.0
        }

        // Process diffs from scanner
        startDiffProcessing()
    }

    public func stop() {
        scanner.stopPolling()
    }

    public func scanNow() {
        Task {
            if let diff = await scanner.scan() {
                alertEngine.processDiff(
                    diff,
                    rules: settings.alertRules,
                    securityMode: settings.securityMode,
                    soundEnabled: settings.soundEnabled
                )
            }
        }
    }

    public func killProcess(pid: Int32, force: Bool = false) -> ProcessManager.KillResult {
        let result = force
            ? ProcessManager.forceKill(pid: pid)
            : ProcessManager.terminate(pid: pid)
        scanner.rescanSoon()
        return result
    }

    private func startDiffProcessing() {
        // Override scanner's scan to feed diffs to alert engine.
        // We re-start polling with a wrapper that processes diffs.
        scanner.stopPolling()

        let pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if let diff = await self.scanner.scan(), !diff.isEmpty {
                    self.alertEngine.processDiff(
                        diff,
                        rules: self.settings.alertRules,
                        securityMode: self.settings.securityMode,
                        soundEnabled: self.settings.soundEnabled
                    )
                }
                let interval = self.settings.pollInterval
                try? await Task.sleep(for: .seconds(interval))
            }
        }
        _ = pollingTask // retained by Task runtime
    }
}
