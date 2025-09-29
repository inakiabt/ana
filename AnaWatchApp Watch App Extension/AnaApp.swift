import SwiftUI
import ClockKit

@main
struct AnaApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutManager)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                workoutManager.persistForBackground()
            case .active:
                workoutManager.refreshFromStore()
            default:
                break
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "anaWorkout")
    }
}
