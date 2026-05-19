import Testing
@testable import PortSheriffKit

@Suite("LsofParser")
struct LsofParserTests {

    @Test("parses single process with one port")
    func singleProcess() {
        let output = """
        p1234
        cnode
        u501
        n127.0.0.1:3000
        """
        let entries = LsofParser.parse(output: output)
        #expect(entries.count == 1)
        #expect(entries[0].port == 3000)
        #expect(entries[0].address == "127.0.0.1")
        #expect(entries[0].processName == "node")
        #expect(entries[0].pid == 1234)
        #expect(entries[0].uid == 501)
    }

    @Test("parses process with multiple listening sockets")
    func multipleSocketsSameProcess() {
        let output = """
        p1234
        cnode
        u501
        n127.0.0.1:3000
        n[::1]:3000
        """
        let entries = LsofParser.parse(output: output)
        #expect(entries.count == 2)
        #expect(entries[0].address == "127.0.0.1")
        #expect(entries[0].port == 3000)
        #expect(entries[1].address == "::1")
        #expect(entries[1].port == 3000)
    }

    @Test("parses multiple processes")
    func multipleProcesses() {
        let output = """
        p1234
        cnode
        u501
        n127.0.0.1:3000
        p5678
        cpostgres
        u502
        n*:5432
        """
        let entries = LsofParser.parse(output: output)
        #expect(entries.count == 2)
        #expect(entries[0].processName == "node")
        #expect(entries[0].port == 3000)
        #expect(entries[1].processName == "postgres")
        #expect(entries[1].port == 5432)
        #expect(entries[1].address == "*")
    }

    @Test("handles IPv6 wildcard address")
    func ipv6Wildcard() {
        let output = """
        p100
        cnginx
        u0
        n[::]:8080
        """
        let entries = LsofParser.parse(output: output)
        #expect(entries.count == 1)
        #expect(entries[0].address == "::")
        #expect(entries[0].port == 8080)
    }

    @Test("returns empty array for empty output")
    func emptyOutput() {
        let entries = LsofParser.parse(output: "")
        #expect(entries.isEmpty)
    }

    @Test("skips lines with unrecognized field tags")
    func unrecognizedFields() {
        let output = """
        p1234
        cnode
        u501
        f12
        PTCP
        tIPv4
        TST=LISTEN
        n127.0.0.1:3000
        """
        let entries = LsofParser.parse(output: output)
        #expect(entries.count == 1)
        #expect(entries[0].port == 3000)
    }

    @Test("skips n lines without valid port")
    func invalidNameLine() {
        let output = """
        p1234
        cnode
        u501
        n(no port here)
        n127.0.0.1:3000
        """
        let entries = LsofParser.parse(output: output)
        #expect(entries.count == 1)
        #expect(entries[0].port == 3000)
    }

    // Address parsing

    @Test("parses IPv4 address:port")
    func parseIPv4() {
        let result = LsofParser.parseAddressPort("127.0.0.1:3000")
        #expect(result?.address == "127.0.0.1")
        #expect(result?.port == 3000)
    }

    @Test("parses wildcard address")
    func parseWildcard() {
        let result = LsofParser.parseAddressPort("*:5432")
        #expect(result?.address == "*")
        #expect(result?.port == 5432)
    }

    @Test("parses IPv6 address in brackets")
    func parseIPv6() {
        let result = LsofParser.parseAddressPort("[::1]:3000")
        #expect(result?.address == "::1")
        #expect(result?.port == 3000)
    }

    @Test("parses IPv6 wildcard in brackets")
    func parseIPv6Wildcard() {
        let result = LsofParser.parseAddressPort("[::]:8080")
        #expect(result?.address == "::")
        #expect(result?.port == 8080)
    }

    @Test("returns nil for invalid format")
    func parseInvalid() {
        #expect(LsofParser.parseAddressPort("nocolon") == nil)
        #expect(LsofParser.parseAddressPort("") == nil)
        #expect(LsofParser.parseAddressPort("host:notanumber") == nil)
    }
}
