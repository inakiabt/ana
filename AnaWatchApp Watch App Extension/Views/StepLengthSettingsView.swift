import SwiftUI

private enum StepLengthUnit: String, CaseIterable, Identifiable {
    case centimeters
    case inches

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .centimeters:
            return "cm"
        case .inches:
            return "in"
        }
    }

    var unit: UnitLength {
        switch self {
        case .centimeters:
            return .centimeters
        case .inches:
            return .inches
        }
    }

    func toMeters(_ value: Double) -> Double {
        Measurement(value: value, unit: unit).converted(to: .meters).value
    }

    func fromMeters(_ meters: Double) -> Double {
        Measurement(value: meters, unit: .meters).converted(to: unit).value
    }
}

private enum CalibrationDistanceUnit: String, CaseIterable, Identifiable {
    case meters
    case feet

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .meters:
            return "m"
        case .feet:
            return "ft"
        }
    }

    var unit: UnitLength {
        switch self {
        case .meters:
            return .meters
        case .feet:
            return .feet
        }
    }

    func toMeters(_ value: Double) -> Double {
        Measurement(value: value, unit: unit).converted(to: .meters).value
    }

    func fromMeters(_ meters: Double) -> Double {
        Measurement(value: meters, unit: .meters).converted(to: unit).value
    }
}

struct StepLengthSettingsView: View {
    @Binding var profile: UserProfile
    var isOnboarding: Bool = false
    var onComplete: ((Bool) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var stepLengthValue: String
    @State private var selectedUnit: StepLengthUnit
    @State private var previousUnit: StepLengthUnit

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    init(profile: Binding<UserProfile>, isOnboarding: Bool = false, onComplete: ((Bool) -> Void)? = nil) {
        self._profile = profile
        self.isOnboarding = isOnboarding
        self.onComplete = onComplete
        let initialUnit: StepLengthUnit = .centimeters
        _selectedUnit = State(initialValue: initialUnit)
        _previousUnit = State(initialValue: initialUnit)
        let meters = profile.wrappedValue.stepLengthMeasurement.converted(to: .meters).value
        let value = StepLengthSettingsView.numberFormatter.string(from: NSNumber(value: initialUnit.fromMeters(meters))) ?? ""
        _stepLengthValue = State(initialValue: value)
    }

    var body: some View {
        List {
            if isOnboarding {
                Section {
                    Text("Personalize your step length so Ana can translate desk treadmill steps into accurate distance.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Section("Personal step length") {
                Picker("Units", selection: $selectedUnit) {
                    ForEach(StepLengthUnit.allCases) { unit in
                        Text(unit.localizedName.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Step length", text: $stepLengthValue)
                    .keyboardType(.decimalPad)

                Text("A precise step length keeps your indoor distance estimates trustworthy when your arms stay planted on the desk.")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Button("Save Step Length", action: saveStepLength)
            }

            Section("Suggested from height") {
                Text("Estimated \(estimatedStepLengthDisplay)")
                Text("Update height or gender for a better starting point, or accept the suggestion.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Button("Use Estimated Value", action: useEstimatedStepLength)
                NavigationLink("Update height & gender") {
                    HeightAndGenderView(profile: $profile)
                }
            }

            Section("Calibrate") {
                Text("Walk a known distance at your usual speed to dial in a gold-standard stride.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                NavigationLink("Calibrate Step Length") {
                    StepLengthCalibrationView(profile: $profile)
                }
            }
        }
        .navigationTitle("Step Length")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onComplete {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { finish(completed: true, onComplete: onComplete) }
                }
                if isOnboarding {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Later") { finish(completed: false, onComplete: onComplete) }
                    }
                }
            }
        }
        .onAppear(perform: syncFromProfile)
        .onChange(of: selectedUnit, perform: convertStepLengthInput)
        .onChange(of: profile) { _ in syncFromProfile() }
    }

    private var estimatedStepLengthDisplay: String {
        let estimatedMeters = profile.estimatedStepLength
        let converted = selectedUnit.fromMeters(estimatedMeters)
        let formatted = StepLengthSettingsView.numberFormatter.string(from: NSNumber(value: converted)) ?? "--"
        return "\(formatted) \(selectedUnit.localizedName)"
    }

    private func syncFromProfile() {
        let meters = profile.stepLengthMeasurement.converted(to: .meters).value
        let converted = selectedUnit.fromMeters(meters)
        let formatted = StepLengthSettingsView.numberFormatter.string(from: NSNumber(value: converted)) ?? ""
        stepLengthValue = formatted
        previousUnit = selectedUnit
    }

    private func saveStepLength() {
        let sanitized = stepLengthValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(sanitized), value > 0 else { return }
        let meters = selectedUnit.toMeters(value)
        let clamped = min(max(meters, 0.35), 1.5)
        profile.stepLengthInMeters = clamped
        syncFromProfile()
    }

    private func useEstimatedStepLength() {
        profile.stepLengthInMeters = nil
        syncFromProfile()
    }

    private func convertStepLengthInput(_ newUnit: StepLengthUnit) {
        let sanitized = stepLengthValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Double(sanitized) {
            let meters = previousUnit.toMeters(value)
            let converted = newUnit.fromMeters(meters)
            let formatted = StepLengthSettingsView.numberFormatter.string(from: NSNumber(value: converted)) ?? ""
            stepLengthValue = formatted
        } else {
            syncFromProfile()
        }
        previousUnit = newUnit
    }

    private func finish(completed: Bool, onComplete: @escaping (Bool) -> Void) {
        dismiss()
        onComplete(completed)
    }
}

private struct HeightAndGenderView: View {
    @Binding var profile: UserProfile

    @Environment(\.dismiss) private var dismiss
    @State private var heightValue: String
    @State private var heightUnit: StepLengthUnit
    @State private var selectedGender: UserProfile.Gender
    @State private var previousHeightUnit: StepLengthUnit

    init(profile: Binding<UserProfile>) {
        self._profile = profile
        let initialUnit: StepLengthUnit = .centimeters
        _heightUnit = State(initialValue: initialUnit)
        _previousHeightUnit = State(initialValue: initialUnit)
        if let height = profile.wrappedValue.heightInMeters {
            let converted = initialUnit.fromMeters(height)
            let formatted = StepLengthSettingsView.numberFormatter.string(from: NSNumber(value: converted)) ?? ""
            _heightValue = State(initialValue: formatted)
        } else {
            _heightValue = State(initialValue: "")
        }
        _selectedGender = State(initialValue: profile.wrappedValue.gender ?? .unspecified)
    }

    var body: some View {
        List {
            Section("Height") {
                Picker("Units", selection: $heightUnit) {
                    ForEach(StepLengthUnit.allCases) { unit in
                        Text(unit.localizedName.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Height", text: $heightValue)
                    .keyboardType(.decimalPad)

                Text("Providing your height lets Ana suggest a more realistic starting stride length.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Section("Gender") {
                Picker("Gender", selection: $selectedGender) {
                    Text(UserProfile.Gender.unspecified.localizedName).tag(UserProfile.Gender.unspecified)
                    ForEach(UserProfile.Gender.allCases.filter { $0 != .unspecified }) { gender in
                        Text(gender.localizedName).tag(gender)
                    }
                }
            }

            Button("Save", action: saveProfile)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: heightUnit, perform: convertHeightInput)
    }

    private func saveProfile() {
        let sanitized = heightValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Double(sanitized), value > 0 {
            profile.heightInMeters = heightUnit.toMeters(value)
        } else {
            profile.heightInMeters = nil
        }
        if selectedGender == .unspecified {
            profile.gender = nil
        } else {
            profile.gender = selectedGender
        }
        dismiss()
    }

    private func convertHeightInput(_ newUnit: StepLengthUnit) {
        let sanitized = heightValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Double(sanitized) {
            let meters = previousHeightUnit.toMeters(value)
            let converted = newUnit.fromMeters(meters)
            let formatted = StepLengthSettingsView.numberFormatter.string(from: NSNumber(value: converted)) ?? ""
            heightValue = formatted
        }
        previousHeightUnit = newUnit
    }
}

private struct StepLengthCalibrationView: View {
    @Binding var profile: UserProfile

    @Environment(\.dismiss) private var dismiss
    @State private var distanceValue: String = "10"
    @State private var distanceUnit: CalibrationDistanceUnit = .meters
    @State private var stepCountValue: String = ""
    @State private var resultText: String?

    var body: some View {
        List {
            Section("How it works") {
                Text("1. Measure a short distance (for example 10 meters or 30 feet).")
                Text("2. Set your treadmill to the speed you usually walk at your desk.")
                Text("3. Walk the distance and count every step.")
                Text("4. Enter the distance and your step count below to save the exact step length.")
            }

            Section("Calibrate") {
                Picker("Distance units", selection: $distanceUnit) {
                    ForEach(CalibrationDistanceUnit.allCases) { unit in
                        Text(unit.localizedName.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Known distance", text: $distanceValue)
                    .keyboardType(.decimalPad)

                TextField("Steps taken", text: $stepCountValue)
                    .keyboardType(.numberPad)

                Button("Save Calibration", action: saveCalibration)

                if let resultText {
                    Text(resultText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Calibrate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func saveCalibration() {
        let sanitizedDistance = distanceValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedSteps = stepCountValue
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let distance = Double(sanitizedDistance), distance > 0 else { return }
        guard let steps = Double(sanitizedSteps), steps > 0 else { return }
        let meters = distanceUnit.toMeters(distance)
        let stepLength = meters / steps
        let clamped = min(max(stepLength, 0.35), 1.5)
        profile.stepLengthInMeters = clamped
        let converted = StepLengthUnit.centimeters.fromMeters(clamped)
        let formatted = StepLengthSettingsView.numberFormatter.string(from: NSNumber(value: converted)) ?? "--"
        resultText = "Saved \(formatted) cm per step"
    }
}
