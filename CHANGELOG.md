# Changelog

All notable changes to Port Sheriff are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Initial release scaffold.
- `PortScanner` polling TCP listeners via `lsof -F`.
- `LsofParser` for machine-format `lsof` output.
- `DiffEngine` for open/close/change detection across scans.
- `ProcessManager` for SIGTERM/SIGKILL, process path lookup, ownership and system-process checks.
- `AlertEngine` with whitelist/blocklist rule evaluation, macOS notifications, and per-session deduplication.
- `SettingsStore` backed by `UserDefaults` with default whitelist rules.
- `AppState` coordinator with idempotent start/stop and cancellable diff-processing task.
- SwiftUI menubar UI: `PortListView`, `AlertsView`, `RulesView`, `RuleEditorView`, `SettingsView`, `MenubarPopover`.
- 33 unit tests across parser, diff engine, process manager, and alert engine.
