import SwiftUI

@main
struct PortSheriffApp: App {
    var body: some Scene {
        MenuBarExtra("Port Sheriff", systemImage: "shield") {
            Text("Loading...")
        }
        .menuBarExtraStyle(.window)
    }
}
