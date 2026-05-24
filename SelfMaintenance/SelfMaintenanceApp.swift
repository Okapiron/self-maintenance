import SwiftData
import SwiftUI

@main
struct SelfMaintenanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [MaintenanceItem.self, MaintenanceLog.self])
    }
}
