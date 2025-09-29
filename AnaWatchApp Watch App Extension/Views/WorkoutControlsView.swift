import SwiftUI

struct WorkoutControlsView: View {
    @EnvironmentObject private var workoutManager: WorkoutManager

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                Label(workoutManager.sessionState == .running ? "Pause" : "Resume",
                      systemImage: workoutManager.sessionState == .running ? "pause.fill" : "play.fill")
                    .font(.body)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive, action: workoutManager.endWorkout) {
                Label("End", systemImage: "stop.fill")
                    .font(.body)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func toggle() {
        switch workoutManager.sessionState {
        case .running:
            workoutManager.pauseWorkout()
        case .paused:
            workoutManager.resumeWorkout()
        default:
            break
        }
    }
}
