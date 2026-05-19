import Foundation

/// Parses lsof -F format output into structured port info.
public enum LsofParser {

    /// Parse machine-format lsof output into RawPortInfo entries.
    /// Expected input: output of `lsof -iTCP -sTCP:LISTEN -nP -F pcnu`
    public static func parse(output: String) -> [RawPortInfo] {
        var entries: [RawPortInfo] = []
        var currentPID: Int32?
        var currentCommand: String?
        var currentUID: UInt32?

        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let tag = trimmed.first!
            let value = String(trimmed.dropFirst())

            switch tag {
            case "p":
                currentPID = Int32(value)
                currentCommand = nil
                currentUID = nil
            case "c":
                currentCommand = value
            case "u":
                currentUID = UInt32(value)
            case "n":
                guard let pid = currentPID,
                      let command = currentCommand,
                      let uid = currentUID,
                      let parsed = parseAddressPort(value)
                else { continue }

                entries.append(RawPortInfo(
                    port: parsed.port,
                    address: parsed.address,
                    processName: command,
                    pid: pid,
                    uid: uid
                ))
            default:
                break
            }
        }

        return entries
    }

    /// Parse "address:port" string from lsof name field.
    /// Handles IPv4 (127.0.0.1:3000), wildcard (*:5432), and IPv6 ([::1]:3000).
    public static func parseAddressPort(_ name: String) -> (address: String, port: UInt16)? {
        guard !name.isEmpty else { return nil }

        if name.hasPrefix("[") {
            // IPv6: [address]:port
            guard let closeBracket = name.firstIndex(of: "]") else { return nil }
            let afterBracket = name.index(after: closeBracket)
            guard afterBracket < name.endIndex, name[afterBracket] == ":" else { return nil }
            let address = String(name[name.index(after: name.startIndex)..<closeBracket])
            let portStr = String(name[name.index(after: afterBracket)...])
            guard let port = UInt16(portStr) else { return nil }
            return (address, port)
        } else {
            // IPv4 or wildcard: address:port (use last colon to handle edge cases)
            guard let colonIndex = name.lastIndex(of: ":") else { return nil }
            let address = String(name[..<colonIndex])
            let portStr = String(name[name.index(after: colonIndex)...])
            guard !address.isEmpty, let port = UInt16(portStr) else { return nil }
            return (address, port)
        }
    }
}
