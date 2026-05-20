# Port Sheriff

A native macOS menubar app that shows every TCP listening port on your machine, which process owns it, and lets you kill it with one click. Alerts on unknown or suspicious ports.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue) ![Swift](https://img.shields.io/badge/swift-6.0-orange) ![License](https://img.shields.io/badge/license-MIT-green)

![Port Sheriff popover](docs/screenshot.png)

## Features

- Live list of TCP listening ports with process name, PID, address, and command path
- One-click kill (SIGTERM, escalates to SIGKILL after 3 s)
- Alert engine with whitelist/blocklist rules (port, port range, process name)
- macOS notifications for unknown ports and process changes on existing ports
- Adaptive polling — slows down when nothing changes
- Zero external runtime dependencies
- Hidden from Dock (menubar-only)

## Requirements

- macOS 14 (Sonoma) or newer
- Apple Silicon or Intel
- Swift 6 toolchain (Xcode 16+) for building from source

## Install

### From source

```bash
git clone https://github.com/YOUR_USER/PortSheriff.git
cd PortSheriff
swift run PortSheriff
```

### Build a `.app` bundle

```bash
./scripts/build-app.sh
open build/PortSheriff.app
```

Drag `build/PortSheriff.app` into `/Applications`.

## Usage

1. Launch — shield icon appears in the menubar.
2. Click the icon to open the popover.
3. **Ports** tab lists active listeners. Click a row to expand details. Click **Kill** to terminate.
4. **Alerts** tab shows recent open/close/change events.
5. **Rules** tab manages whitelist and blocklist entries.
6. Gear icon opens **Settings** — poll interval, sound, security mode, launch at login.

## How it works

Port Sheriff polls `lsof -iTCP -sTCP:LISTEN -nP -F pcnu` on a hybrid timer (default 5 s, doubles after 10 unchanged scans). Output is parsed in-process, diffed against the previous snapshot, and changes flow through the alert engine.

No kernel extensions, no network capture, no elevated privileges. Just `lsof` and POSIX signals.

## Security model

- Port Sheriff never sends network traffic.
- It does not require root.
- Killing a process owned by another user will fail with `EPERM` — by design.
- See [SECURITY.md](SECURITY.md) for vulnerability disclosure.

## Limitations

- TCP only (UDP listeners are not enumerated).
- Process metadata reflects what `lsof` sees at scan time; very short-lived processes may be missed between scans.
- Not sandboxed — required to shell out to `/usr/sbin/lsof` and send signals. Will not run as a Mac App Store build.

## Development

```bash
swift build        # compile
swift test         # 33 tests
swift run PortSheriff
```

Open in Xcode: `open Package.swift`.

Architecture: single-process SwiftUI `MenuBarExtra` app. Services layer (`PortScanner`, `AlertEngine`, `ProcessManager`, `SettingsStore`) coordinated by `AppState`, observed by SwiftUI views via `@Observable`.

See [CONTRIBUTING.md](CONTRIBUTING.md) for code style and PR workflow.

## License

[MIT](LICENSE)
