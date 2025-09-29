import SwiftUI

struct CalibrationWizardView: View {
    @Binding var userProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var knownDistance: Double = 10.0 // meters
    @State private var unitSystem: UnitSystem = .metric
    @State private var stepCount: String = ""
    @State private var showingResults = false
    @State private var calculatedStepLength: Double = 0.0
    
    private let steps = [
        "Prepare Measurement",
        "Set Up Distance", 
        "Walk & Count",
        "Calculate Results"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress indicator
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding(.horizontal)
                
                Text("Step \(currentStep + 1) of \(steps.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(steps[currentStep])
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Step content
                Group {
                    switch currentStep {
                    case 0:
                        PrepareStepView()
                    case 1:
                        DistanceSetupView(knownDistance: $knownDistance, unitSystem: $unitSystem)
                    case 2:
                        WalkAndCountView(stepCount: $stepCount)
                    case 3:
                        ResultsView(
                            calculatedStepLength: calculatedStepLength,
                            knownDistance: knownDistance,
                            unitSystem: unitSystem,
                            stepCount: Int(stepCount) ?? 0
                        )
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == steps.count - 1 ? "Save" : "Next") {
                        if currentStep == steps.count - 1 {
                            saveCalibration()
                        } else if currentStep == 2 {
                            // Calculate step length before moving to results
                            calculateStepLength()
                            currentStep += 1
                        } else {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 2:
            return !stepCount.isEmpty && Int(stepCount) != nil && Int(stepCount)! > 0
        default:
            return true
        }
    }
    
    private func calculateStepLength() {
        guard let steps = Int(stepCount), steps > 0 else { return }
        
        // Convert distance to meters
        let distanceInMeters: Double
        if unitSystem == .metric {
            distanceInMeters = knownDistance
        } else {
            distanceInMeters = knownDistance * 0.3048 // feet to meters
        }
        
        // Calculate step length: Step Length = Distance / Step Count
        let stepLengthInMeters = distanceInMeters / Double(steps)
        calculatedStepLength = stepLengthInMeters * 100.0 // convert to cm
    }
    
    private func saveCalibration() {
        userProfile.stepLength = calculatedStepLength
        userProfile.hasCustomStepLength = true
        dismiss()
    }
}

struct PrepareStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 15) {
                Text("Get Ready")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Find a clear, flat area")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Have a measuring tape ready")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Set your treadmill to walking speed")
                    }
                }
                .font(.body)
            }
            
            Text("This calibration will take about 2-3 minutes and will give you the most accurate step length for your treadmill workouts.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct DistanceSetupView: View {
    @Binding var knownDistance: Double
    @Binding var unitSystem: UnitSystem
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "ruler")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Measure a Known Distance")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Use a measuring tape to mark a straight line. We recommend 10 meters (30 feet) for best accuracy.")
                .font(.body)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                Picker("Unit", selection: $unitSystem) {
                    Text("Meters").tag(UnitSystem.metric)
                    Text("Feet").tag(UnitSystem.imperial)
                }
                .pickerStyle(.segmented)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Distance:")
                        Spacer()
                        Text("\(knownDistance, specifier: "%.1f") \(unitSystem == .metric ? "m" : "ft")")
                            .fontWeight(.semibold)
                    }
                    
                    let range = unitSystem == .metric ? 5.0...50.0 : 15.0...150.0
                    Slider(value: $knownDistance, in: range, step: unitSystem == .metric ? 0.5 : 1.0) {
                        Text("Distance")
                    }
                    .accentColor(.orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

struct WalkAndCountView: View {
    @Binding var stepCount: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Walk & Count Steps")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("1.")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Start at one end of your measured distance")
                }
                
                HStack {
                    Text("2.")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Walk at your normal treadmill pace")
                }
                
                HStack {
                    Text("3.")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Count every step until you reach the end")
                }
            }
            .font(.body)
            
            VStack(spacing: 10) {
                Text("How many steps did you take?")
                    .font(.headline)
                
                TextField("Enter step count", text: $stepCount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct ResultsView: View {
    let calculatedStepLength: Double
    let knownDistance: Double
    let unitSystem: UnitSystem
    let stepCount: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Calibration Complete!")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 15) {
                Text("Your Personal Step Length")
                    .font(.headline)
                
                Text("\(calculatedStepLength, specifier: "%.1f") cm")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("(\(calculatedStepLength * 0.393701, specifier: "%.1f") inches)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Calculation Details:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Distance: \(knownDistance, specifier: "%.1f") \(unitSystem == .metric ? "m" : "ft")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Steps: \(stepCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Step Length = Distance ÷ Steps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text("This personalized step length will be used for all your treadmill workouts to ensure accurate distance tracking.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    CalibrationWizardView(userProfile: .constant(UserProfile()))
}