import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject private var workoutManager: WorkoutManager
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                MetricRingView(
                    title: "Heart Rate",
                    value: heartRateDisplay,
                    subtitle: averageHeartRateSubtitle,
                    progress: heartRateProgress,
                    accent: Color("BrandPrimary")
                )

                Text(workoutManager.metrics.elapsedTime.formattedElapsed)
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 10) {
                    MetricTile(title: "Distance", value: distanceDisplay)
                    MetricTile(title: "Pace", value: paceDisplay)
                    MetricTile(title: "Calories", value: caloriesDisplay, unit: "kcal")
                    MetricTile(title: "Steps", value: stepsDisplay, footnote: cadenceSubtitle)
                    MetricTile(title: "Speed", value: speedDisplay, unit: workoutManager.configuration.speedUnit.localizedName)
                    MetricTile(title: "Incline", value: inclineDisplay)
                    MetricTile(title: "Movement", value: movementDisplay, footnote: "intensity")
                    MetricTile(title: "Cadence", value: cadenceDisplay, unit: "spm")
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("Adjust speed")
                        Spacer()
                        Text(speedDisplay + " " + workoutManager.configuration.speedUnit.localizedName)
                            .font(.headline)
                    }
                    HStack(spacing: 12) {
                        Button(action: { adjustSpeed(by: -0.1) }) {
                            Image(systemName: "minus")
                                .padding(8)
                        }
                        .buttonStyle(.bordered)

                        Button(action: { adjustSpeed(by: 0.1) }) {
                            Image(systemName: "plus")
                                .padding(8)
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack {
                        Text("Adjust incline")
                        Spacer()
                        Text(inclineDisplay)
                            .font(.headline)
                    }
                    HStack(spacing: 12) {
                        Button(action: { adjustIncline(by: -0.5) }) {
                            Image(systemName: "minus")
                                .padding(8)
                        }
                        .buttonStyle(.bordered)

                        Button(action: { adjustIncline(by: 0.5) }) {
                            Image(systemName: "plus")
                                .padding(8)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 6)

                WorkoutControlsView()

                NavigationLink("More metrics") {
                    MetricsDetailView(
                        metrics: workoutManager.metrics,
                        configuration: workoutManager.configuration,
                        profile: workoutManager.profile
                    )
                }
                .font(.footnote)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 12)
        }
        .navigationTitle("Workout")
    }

    private var heartRateDisplay: String {
        guard let heartRate = workoutManager.metrics.heartRate else { return "--" }
        return "\(Int(round(heartRate)))"
    }

    private var averageHeartRateSubtitle: String? {
        guard let average = workoutManager.metrics.averageHeartRate else { return nil }
        return "avg \(Int(round(average))) bpm"
    }

    private var heartRateProgress: Double {
        guard let heartRate = workoutManager.metrics.heartRate else { return 0 }
        let maxHR = 190.0
        return min(heartRate / maxHR, 1.0)
    }

    private var distanceDisplay: String {
        MeasurementFormatter.string(
            from: workoutManager.metrics.distance,
            convertedTo: workoutManager.configuration.distanceUnit.unit
        )
    }

    private var paceDisplay: String {
        guard let pace = workoutManager.metrics.pace else { return "--" }
        return MeasurementFormatter.string(from: pace, convertedTo: workoutManager.configuration.distanceUnit.paceUnit)
    }

    private var caloriesDisplay: String {
        String(format: "%.0f", workoutManager.metrics.activeEnergy)
    }

    private var stepsDisplay: String {
        numberFormatter.string(from: NSNumber(value: workoutManager.metrics.steps)) ?? "--"
    }

    private var cadenceDisplay: String {
        guard let cadence = workoutManager.metrics.cadence else { return "--" }
        return String(format: "%.0f", cadence)
    }

    private var cadenceSubtitle: String? {
        guard let cadence = workoutManager.metrics.cadence else { return nil }
        return String(format: "%.0f spm", cadence)
    }

    private var speedDisplay: String {
        String(format: "%.1f", workoutManager.configuration.speed)
    }

    private var inclineDisplay: String {
        String(format: "%.1f%%", workoutManager.configuration.incline)
    }

    private var movementDisplay: String {
        let score = min(max(workoutManager.metrics.movementIntensity * 150.0, 0), 100)
        return String(format: "%.0f%%", score)
    }

    private func adjustSpeed(by delta: Double) {
        var config = workoutManager.configuration
        config.speed = max(0.5, min(12.0, config.speed + delta))
        workoutManager.configuration = config
        AnaStorage.save(configuration: config)
    }

    private func adjustIncline(by delta: Double) {
        var config = workoutManager.configuration
        config.incline = max(0.0, min(20.0, config.incline + delta))
        workoutManager.configuration = config
        AnaStorage.save(configuration: config)
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }
}
