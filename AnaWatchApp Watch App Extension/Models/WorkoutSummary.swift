import Foundation

struct WorkoutSummary: Codable, Equatable {
    var start: Date
    var end: Date
    var duration: TimeInterval
    var distance: Measurement<UnitLength>
    var steps: Int
    var averageHeartRate: Double?
    var activeEnergy: Double
    var configuration: WorkoutConfiguration
    var peakHeartRate: Double?
}

extension WorkoutSummary {
    var formattedDuration: String {
        DateComponentsFormatter.workout.string(from: duration) ?? "--"
    }

    var formattedDistance: String {
        MeasurementFormatter.string(from: distance, convertedTo: configuration.distanceUnit.unit)
    }

    var formattedEnergy: String {
        MeasurementFormatter.kilocalorieFormatter.string(from: Measurement(value: activeEnergy, unit: UnitEnergy.kilocalories))
    }
}
