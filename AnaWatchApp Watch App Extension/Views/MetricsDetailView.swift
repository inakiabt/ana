import SwiftUI

struct MetricsDetailView: View {
    let metrics: WorkoutMetrics
    let configuration: WorkoutConfiguration
    let profile: UserProfile

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        List {
            Section("Workout") {
                HStack {
                    Text("Elapsed")
                    Spacer()
                    Text(metrics.elapsedTime.formattedElapsed)
                }
                HStack {
                    Text("Speed")
                    Spacer()
                    Text(String(format: "%.1f %@", configuration.speed, configuration.speedUnit.localizedName))
                }
                HStack {
                    Text("Incline")
                    Spacer()
                    Text(String(format: "%.1f%%", configuration.incline))
                }
                HStack {
                    Text("Step length")
                    Spacer()
                    Text(stepLengthSummary)
                }
                if let heightSummary {
                    HStack {
                        Text("Height")
                        Spacer()
                        Text(heightSummary)
                    }
                }
                HStack {
                    Text("Projected 30 min")
                    Spacer()
                    Text(projectedDistance)
                }
            }

            Section("Movement") {
                HStack {
                    Text("Steps")
                    Spacer()
                    Text(numberFormatter.string(from: NSNumber(value: metrics.steps)) ?? "--")
                }
                HStack {
                    Text("Cadence")
                    Spacer()
                    Text(cadenceSummary)
                }
                HStack {
                    Text("Stride")
                    Spacer()
                    Text(strideLength)
                }
                HStack {
                    Text("Movement score")
                    Spacer()
                    Text(movementScore)
                }
            }

            Section("Health") {
                HStack {
                    Text("Heart rate")
                    Spacer()
                    Text(heartRateDetail)
                }
                HStack {
                    Text("Calories")
                    Spacer()
                    Text(String(format: "%.0f kcal", metrics.activeEnergy))
                }
                HStack {
                    Text("Distance")
                    Spacer()
                    Text(
                        MeasurementFormatter.string(
                            from: metrics.distance,
                            convertedTo: configuration.distanceUnit.unit
                        )
                    )
                }
                if let pace = metrics.pace {
                    HStack {
                        Text("Average pace")
                        Spacer()
                        Text(
                            MeasurementFormatter.string(
                                from: pace,
                                convertedTo: configuration.distanceUnit.paceUnit
                            )
                        )
                    }
                }
            }
        }
        .navigationTitle("Metrics")
    }

    private var projectedDistance: String {
        let futureMeters = configuration.speedInMetersPerSecond * (30 * 60)
        let measurement = Measurement(value: futureMeters, unit: UnitLength.meters)
        return MeasurementFormatter.string(
            from: measurement,
            convertedTo: configuration.distanceUnit.unit
        )
    }

    private var cadenceSummary: String {
        guard let cadence = metrics.cadence else { return "--" }
        return String(format: "%.0f spm", cadence)
    }

    private var strideLength: String {
        guard metrics.steps > 0 else { return "--" }
        let stride = metrics.distanceInMeters / Double(metrics.steps)
        let measurement = Measurement(value: stride, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit]
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter.string(from: measurement.converted(to: .centimeters))
    }

    private var movementScore: String {
        let score = min(max(metrics.movementIntensity * 150.0, 0), 100)
        return String(format: "%.0f%%", score)
    }

    private var stepLengthSummary: String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit]
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        let centimeters = profile.stepLengthMeasurement.converted(to: .centimeters)
        var summary = formatter.string(from: centimeters)
        if profile.usingEstimatedStepLength {
            summary += " · estimated"
        }
        return summary
    }

    private var heightSummary: String? {
        guard let height = profile.height else { return nil }
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit]
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: height.converted(to: .centimeters))
    }

    private var heartRateDetail: String {
        let current = metrics.heartRate.map { "\(Int($0)) bpm" } ?? "--"
        if let average = metrics.averageHeartRate {
            return "\(current) · avg \(Int(average))"
        }
        return current
    }
}
