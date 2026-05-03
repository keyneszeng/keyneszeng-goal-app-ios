import SwiftUI

@main
struct KungFuFollowApp: App {
    @StateObject private var checkIns = CheckInStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(checkIns)
        }
    }
}
