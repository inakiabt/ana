import SwiftUI

struct SetupView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var speed: Double = 3.0
    @State private var incline: Double = 0.0
    @State private var unitSystem: UnitSystem = .imperial
    @State private var walkingStepsPerMile: Double = 2200
    @State private var runningStepsPerMile: Double = 1800
    @State private var showingAdvancedSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Workout Setup")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Unit System Settings
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Unit System")
                            .font(.headline)
                        
                        Picker("Unit System", selection: $unitSystem) {
                            ForEach(UnitSystem.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Speed Settings
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Speed")
                            .font(.headline)
                        
                        HStack {
                            Text("\(speed, specifier: "%.1f") \(unitSystem.speedUnit)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(width: 100)
                            
                            Spacer()
                        }
                        
                        let speedRange = unitSystem == .imperial ? 1.0...12.0 : 1.6...19.3 // Convert mph to km/h
                        Slider(value: $speed, in: speedRange, step: 0.1) {
                            Text("Speed")
                        }
                        .accentColor(.blue)
                        
                        HStack {
                            Text(unitSystem == .imperial ? "1.0" : "1.6")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(unitSystem == .imperial ? "12.0" : "19.3")
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
                            PresetButton(title: "Easy Walk", speed: unitSystem == .imperial ? 2.5 : 4.0, incline: 0.0, unitSystem: unitSystem) {
                                speed = unitSystem == .imperial ? 2.5 : 4.0
                                incline = 0.0
                            }
                            
                            PresetButton(title: "Brisk Walk", speed: unitSystem == .imperial ? 3.5 : 5.6, incline: 2.0, unitSystem: unitSystem) {
                                speed = unitSystem == .imperial ? 3.5 : 5.6
                                incline = 2.0
                            }
                            
                            PresetButton(title: "Hill Walk", speed: unitSystem == .imperial ? 3.0 : 4.8, incline: 5.0, unitSystem: unitSystem) {
                                speed = unitSystem == .imperial ? 3.0 : 4.8
                                incline = 5.0
                            }
                            
                            PresetButton(title: "Light Jog", speed: unitSystem == .imperial ? 5.0 : 8.0, incline: 1.0, unitSystem: unitSystem) {
                                speed = unitSystem == .imperial ? 5.0 : 8.0
                                incline = 1.0
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Advanced Settings
                    VStack(alignment: .leading, spacing: 10) {
                        Button(action: { showingAdvancedSettings.toggle() }) {
                            HStack {
                                Text("Advanced Settings")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: showingAdvancedSettings ? "chevron.up" : "chevron.down")
                            }
                        }
                        .foregroundColor(.primary)
                        
                        if showingAdvancedSettings {
                            Group {
                                Text("Step Estimation")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.top)
                                
                                HStack {
                                    Text("Walking:")
                                    Spacer()
                                    Text("\(Int(walkingStepsPerMile)) steps/mile")
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $walkingStepsPerMile, in: 1800...2800, step: 50) {
                                    Text("Walking Steps Per Mile")
                                }
                                .accentColor(.green)
                                
                                HStack {
                                    Text("Running:")
                                    Spacer()
                                    Text("\(Int(runningStepsPerMile)) steps/mile")
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $runningStepsPerMile, in: 1400...2200, step: 50) {
                                    Text("Running Steps Per Mile")
                                }
                                .accentColor(.red)
                                
                                Text("Tip: Customize steps per mile based on your stride length")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
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
            unitSystem = workoutManager.settings.unitSystem
            walkingStepsPerMile = workoutManager.settings.walkingStepsPerMile
            runningStepsPerMile = workoutManager.settings.runningStepsPerMile
        }
        .onChange(of: unitSystem) { newValue in
            // Convert speed when unit system changes
            if newValue == .metric && workoutManager.settings.unitSystem == .imperial {
                speed = speed * 1.60934 // mph to km/h
            } else if newValue == .imperial && workoutManager.settings.unitSystem == .metric {
                speed = speed * 0.621371 // km/h to mph
            }
        }
    }
    
    private func startWorkout() {
        workoutManager.settings.speed = speed
        workoutManager.settings.incline = incline
        workoutManager.settings.unitSystem = unitSystem
        workoutManager.settings.walkingStepsPerMile = walkingStepsPerMile
        workoutManager.settings.runningStepsPerMile = runningStepsPerMile
        workoutManager.startWorkout()
        dismiss()
    }
}

struct PresetButton: View {
    let title: String
    let speed: Double
    let incline: Double
    let unitSystem: UnitSystem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(speed, specifier: "%.1f") \(unitSystem.speedUnit)")
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