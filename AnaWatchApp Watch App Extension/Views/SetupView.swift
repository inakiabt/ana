import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var workoutManager: WorkoutManager
    @State private var configuration: WorkoutConfiguration = .default
    @State private var profile: UserProfile = .default
    @AppStorage("com.ana.profileOnboarded") private var hasCompletedProfileSetup = false
    @State private var showProfileSetup = false
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Set treadmill controls")
                        .font(.headline)
                    Text("Dial in the treadmill speed and incline so Ana can mirror the workout indoors.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }

                Picker("Units", selection: $configuration.speedUnit) {
                    ForEach(WorkoutConfiguration.SpeedUnit.allCases) { unit in
                        Text(unit.localizedName.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Distance", selection: $configuration.distanceUnit) {
                    ForEach(WorkoutConfiguration.DistanceUnit.allCases) { unit in
                        Text(unit.localizedName.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Speed")
                        Spacer()
                        Text(String(format: "%.1f %@", configuration.speed, configuration.speedUnit.localizedName))
                            .font(.headline)
                    }
                    Slider(value: $configuration.speed, in: 0.5...12.0, step: 0.1)
                    Text(speedHint)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Incline")
                        Spacer()
                        Text(String(format: "%.1f%%", configuration.incline))
                            .font(.headline)
                    }
                    Slider(value: $configuration.incline, in: 0.0...20.0, step: 0.5)
                    Text(String(format: "Grade %.2f", configuration.grade))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                NavigationLink {
                    StepLengthSettingsView(profile: $profile)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Step length")
                            Spacer()
                            Text(stepLengthSummary)
                                .font(.headline)
                        }
                        Text(stepLengthFootnote)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if authorizationWarning != nil {
                    Text(authorizationWarning!)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: start) {
                    Text("Start Workout")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(workoutManager.authorizationState != .authorized)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
        .onAppear {
            configuration = workoutManager.configuration
            profile = workoutManager.profile
            if !hasAppeared {
                hasAppeared = true
                presentProfileOnboardingIfNeeded()
            }
        }
        .onChange(of: configuration) { newValue in
            workoutManager.configuration = newValue
            AnaStorage.save(configuration: newValue)
        }
        .onChange(of: profile) { newValue in
            if newValue != workoutManager.profile {
                workoutManager.profile = newValue
            }
        }
        .onChange(of: workoutManager.profile) { newValue in
            if newValue != profile {
                profile = newValue
            }
        }
        .sheet(isPresented: $showProfileSetup) {
            NavigationStack {
                StepLengthSettingsView(profile: $profile, isOnboarding: true) { completed in
                    if completed {
                        hasCompletedProfileSetup = true
                    }
                    showProfileSetup = false
                }
            }
        }
    }

    private var speedHint: String {
        switch configuration.speedUnit {
        case .milesPerHour:
            let metric = configuration.speedMeasurement.converted(to: .kilometersPerHour)
            return String(format: "%.1f km/h", metric.value)
        case .kilometersPerHour:
            let imperial = configuration.speedMeasurement.converted(to: .milesPerHour)
            return String(format: "%.1f mph", imperial.value)
        }
    }

    private var stepLengthSummary: String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit]
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: profile.stepLengthMeasurement.converted(to: .centimeters))
    }

    private var stepLengthFootnote: String {
        if profile.usingEstimatedStepLength {
            if profile.heightInMeters != nil {
                return "Estimated from your height. Calibrate for the most accurate distance."
            } else {
                return "Add your height to get a better starting estimate."
            }
        } else {
            return "Personalized step length used to calculate treadmill distance."
        }
    }

    private func presentProfileOnboardingIfNeeded() {
        guard !hasCompletedProfileSetup else { return }
        let needsPrompt = profile.stepLengthInMeters == nil
        if needsPrompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showProfileSetup = true
            }
        }
    }

    private var authorizationWarning: String? {
        switch workoutManager.authorizationState {
        case .authorized:
            return nil
        case .pending:
            return "Waiting for Health access."
        case .denied:
            return "Enable Health permissions on your iPhone to save workouts to Apple Health."
        }
    }

    private func start() {
        workoutManager.configuration = configuration
        workoutManager.profile = profile
        workoutManager.startWorkout()
    }
}
