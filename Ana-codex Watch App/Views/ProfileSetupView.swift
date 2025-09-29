import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var userProfile: UserProfile
    @State private var selectedTier: Int = 0 // 0 = Manual, 1 = Height-based, 2 = Calibration
    @State private var showingCalibration = false
    
    init(userProfile: UserProfile) {
        self._userProfile = State(initialValue: userProfile)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Step Length Setup")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Accurate step length ensures precise distance tracking for your desk treadmill workouts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Tier Selection
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Configuration Method")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            TierSelectionRow(
                                title: "Manual Input",
                                subtitle: "Enter your step length directly",
                                isSelected: selectedTier == 0
                            ) {
                                selectedTier = 0
                            }
                            
                            TierSelectionRow(
                                title: "Height-Based Estimate",
                                subtitle: "Calculate from your height",
                                isSelected: selectedTier == 1
                            ) {
                                selectedTier = 1
                            }
                            
                            TierSelectionRow(
                                title: "Guided Calibration",
                                subtitle: "Precise measurement process",
                                isSelected: selectedTier == 2
                            ) {
                                selectedTier = 2
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Configuration Content based on selected tier
                    Group {
                        if selectedTier == 0 {
                            ManualStepLengthView(userProfile: $userProfile)
                        } else if selectedTier == 1 {
                            HeightBasedView(userProfile: $userProfile)
                        } else {
                            CalibrationView(userProfile: $userProfile, showingCalibration: $showingCalibration)
                        }
                    }
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: saveProfile) {
                        Text("Save Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
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
        .sheet(isPresented: $showingCalibration) {
            CalibrationWizardView(userProfile: $userProfile)
        }
    }
    
    private func saveProfile() {
        workoutManager.settings.userProfile = userProfile
        dismiss()
    }
}

struct TierSelectionRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct ManualStepLengthView: View {
    @Binding var userProfile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Manual Step Length")
                .font(.headline)
            
            Text("Enter your step length (stride length) manually. You can measure this by walking a known distance and dividing by your step count.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                HStack {
                    Text("Step Length:")
                    Spacer()
                    Text("\(userProfile.stepLength, specifier: "%.1f") cm")
                        .fontWeight(.semibold)
                }
                
                Slider(value: $userProfile.stepLength, in: 40.0...120.0, step: 0.5) {
                    Text("Step Length")
                }
                .accentColor(.blue)
                .onChange(of: userProfile.stepLength) { _ in
                    userProfile.hasCustomStepLength = true
                }
                
                HStack {
                    Text("40 cm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("120 cm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HeightBasedView: View {
    @Binding var userProfile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Height-Based Estimation")
                .font(.headline)
            
            Text("We'll estimate your step length based on your height and gender using proven formulas.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                // Height Input
                VStack(spacing: 8) {
                    HStack {
                        Text("Height:")
                        Spacer()
                        Text("\(userProfile.height, specifier: "%.0f") cm")
                            .fontWeight(.semibold)
                    }
                    
                    Slider(value: $userProfile.height, in: 140.0...210.0, step: 1.0) {
                        Text("Height")
                    }
                    .accentColor(.green)
                    .onChange(of: userProfile.height) { _ in
                        updateEstimatedStepLength()
                    }
                }
                
                // Gender Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender:")
                        .font(.body)
                    
                    Picker("Gender", selection: $userProfile.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: userProfile.gender) { _ in
                        updateEstimatedStepLength()
                    }
                }
                
                // Estimated Step Length Display
                HStack {
                    Text("Estimated Step Length:")
                    Spacer()
                    Text("\(userProfile.stepLength, specifier: "%.1f") cm")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            updateEstimatedStepLength()
        }
    }
    
    private func updateEstimatedStepLength() {
        userProfile.stepLength = userProfile.estimatedStepLength()
        userProfile.hasCustomStepLength = false
    }
}

struct CalibrationView: View {
    @Binding var userProfile: UserProfile
    @Binding var showingCalibration: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Guided Calibration")
                .font(.headline)
            
            Text("For the most accurate results, we'll guide you through a simple calibration process using your treadmill.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                CalibrationStepRow(
                    number: "1",
                    title: "Measure Distance",
                    description: "Mark a known distance (10m or 30ft)"
                )
                
                CalibrationStepRow(
                    number: "2",
                    title: "Set Treadmill Speed",
                    description: "Use your usual walking speed"
                )
                
                CalibrationStepRow(
                    number: "3",
                    title: "Count Steps",
                    description: "Walk the distance and count steps"
                )
                
                CalibrationStepRow(
                    number: "4",
                    title: "Calculate",
                    description: "App calculates your step length"
                )
            }
            
            Button(action: { showingCalibration = true }) {
                HStack {
                    Image(systemName: "ruler")
                    Text("Start Calibration")
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(8)
            }
            
            if userProfile.hasCustomStepLength {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Calibrated: \(userProfile.stepLength, specifier: "%.1f") cm")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CalibrationStepRow: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ProfileSetupView(userProfile: UserProfile())
        .environmentObject(WorkoutManager())
}