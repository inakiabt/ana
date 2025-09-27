import SwiftUI
import HealthKit

struct ContentView: View {
    @EnvironmentObject private var workoutManager: WorkoutManager

    var body: some View {
        NavigationStack {
            Group {
                if let summary = workoutManager.summary {
                    SummaryView(summary: summary)
                } else if workoutManager.sessionState == .running || workoutManager.sessionState == .paused {
                    WorkoutView()
                } else {
                    SetupView()
                }
            }
            .navigationTitle("Ana")
        }
        .onAppear {
            workoutManager.requestAuthorization()
        }
        .alert(item: $workoutManager.activeError) { error in
            Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Resume workout?", isPresented: $workoutManager.showResumePrompt, titleVisibility: .visible) {
            Button("Resume") {
                workoutManager.resumeWorkout()
            }
            Button("End", role: .destructive) {
                workoutManager.endWorkout()
            }
            Button("Dismiss", role: .cancel) {
                workoutManager.acknowledgePrompt()
            }
        } message: {
            Text("We noticed reduced movement. Would you like to resume or end your workout?")
        }
    }
}
