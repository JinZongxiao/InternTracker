import SwiftUI

@main
struct InternTrackerApp: App {
    @StateObject private var store = AttendanceStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1000, minHeight: 680)
        }
    }
}
