import SwiftUI

struct SetupView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var speed: Double = 3.0
    @State private var incline: Double = 0.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Workout Setup")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Speed Settings
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Speed")
                            .font(.headline)
                        
                        HStack {
                            Text("\(speed, specifier: "%.1f") mph")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(width: 80)
                            
                            Spacer()
                        }
                        
                        Slider(value: $speed, in: 1.0...12.0, step: 0.1) {
                            Text("Speed")
                        }
                        .accentColor(.blue)
                        
                        HStack {
                            Text("1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("12.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Incline Settings
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Incline")
                            .font(.headline)
                        
                        HStack {
                            Text("\(incline, specifier: "%.1f")%")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(width: 80)
                            
                            Spacer()
                        }
                        
                        Slider(value: $incline, in: 0.0...15.0, step: 0.5) {
                            Text("Incline")
                        }
                        .accentColor(.orange)
                        
                        HStack {
                            Text("0%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("15%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Quick presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Presets")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            PresetButton(title: "Easy Walk", speed: 2.5, incline: 0.0) {
                                speed = 2.5
                                incline = 0.0
                            }
                            
                            PresetButton(title: "Brisk Walk", speed: 3.5, incline: 2.0) {
                                speed = 3.5
                                incline = 2.0
                            }
                            
                            PresetButton(title: "Hill Walk", speed: 3.0, incline: 5.0) {
                                speed = 3.0
                                incline = 5.0
                            }
                            
                            PresetButton(title: "Light Jog", speed: 5.0, incline: 1.0) {
                                speed = 5.0
                                incline = 1.0
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // Start Button
                    Button(action: startWorkout) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Workout")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            speed = workoutManager.settings.speed
            incline = workoutManager.settings.incline
        }
    }
    
    private func startWorkout() {
        workoutManager.settings.speed = speed
        workoutManager.settings.incline = incline
        workoutManager.startWorkout()
        dismiss()
    }
}

struct PresetButton: View {
    let title: String
    let speed: Double
    let incline: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(speed, specifier: "%.1f") mph")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(incline, specifier: "%.1f")%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SetupView()
        .environmentObject(WorkoutManager())
}