import SwiftUI
import HealthKit

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingSetup = false
    
    var body: some View {
        NavigationView {
            if workoutManager.isWorkoutActive {
                WorkoutView()
            } else {
                VStack(spacing: 20) {
                    Text("Ana")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Treadmill Workout Tracker")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("Start Workout") {
                        showingSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    if !workoutManager.hasHealthPermissions {
                        Button("Grant Health Permissions") {
                            workoutManager.requestHealthPermissions()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingSetup) {
            SetupView()
        }
        .onAppear {
            workoutManager.requestHealthPermissions()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutManager())
}
