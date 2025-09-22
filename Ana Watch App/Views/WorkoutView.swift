import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingEndConfirmation = false
    
    var body: some View {
        TabView {
            // Main metrics view
            ScrollView {
                VStack(spacing: 15) {
                    // Duration and controls
                    VStack(spacing: 10) {
                        Text(formatTime(workoutManager.stats.duration))
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 20) {
                            if workoutManager.isPaused {
                                Button(action: workoutManager.resumeWorkout) {
                                    Image(systemName: "play.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            } else {
                                Button(action: workoutManager.pauseWorkout) {
                                    Image(systemName: "pause.fill")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                            }
                            
                            Button(action: { showingEndConfirmation = true }) {
                                Image(systemName: "stop.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Heart Rate
                    MetricCard(
                        title: "Heart Rate",
                        value: "\(Int(workoutManager.stats.heartRate))",
                        unit: "BPM",
                        color: .red,
                        subtitle: "Avg: \(Int(workoutManager.stats.averageHeartRate))"
                    )
                    
                    // Distance and Pace
                    HStack(spacing: 10) {
                        MetricCard(
                            title: "Distance",
                            value: String(format: "%.2f", workoutManager.stats.distance),
                            unit: "mi",
                            color: .blue
                        )
                        
                        MetricCard(
                            title: "Pace",
                            value: formatPace(workoutManager.stats.pace),
                            unit: "/mi",
                            color: .green
                        )
                    }
                    
                    // Steps and Calories
                    HStack(spacing: 10) {
                        MetricCard(
                            title: "Steps",
                            value: "\(workoutManager.stats.steps)",
                            unit: "",
                            color: .purple
                        )
                        
                        MetricCard(
                            title: "Calories",
                            value: "\(Int(workoutManager.stats.calories))",
                            unit: "cal",
                            color: .orange
                        )
                    }
                }
                .padding()
            }
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Metrics")
            }
            
            // Settings view during workout
            VStack(spacing: 20) {
                Text("Current Settings")
                    .font(.headline)
                
                VStack(spacing: 15) {
                    SettingRow(
                        title: "Speed",
                        value: "\(workoutManager.settings.speed, specifier: "%.1f") mph",
                        color: .blue
                    )
                    
                    SettingRow(
                        title: "Incline",
                        value: "\(workoutManager.settings.incline, specifier: "%.1f")%",
                        color: .orange
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                
                Text("Tip: You can adjust these on your treadmill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .alert("End Workout", isPresented: $showingEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End", role: .destructive) {
                workoutManager.endWorkout()
            }
        } message: {
            Text("Are you sure you want to end your workout?")
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func formatPace(_ pace: Double) -> String {
        if pace == 0 { return "--:--" }
        
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SettingRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WorkoutView()
        .environmentObject(WorkoutManager())
}