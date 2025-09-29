import Foundation

struct WorkoutMetrics: Codable, Equatable {
    var elapsedTime: TimeInterval = 0
    var heartRate: Double?
    var averageHeartRate: Double?
    var activeEnergy: Double = 0
    var steps: Int = 0
    var distance: Measurement<UnitLength> = Measurement(value: 0, unit: .meters)
    var pace: Measurement<UnitSpeed>?
    var incline: Double = 0
    var cadence: Double?
    var movementIntensity: Double = 0
    var speed: Measurement<UnitSpeed> = Measurement(value: 0, unit: .milesPerHour)

    var distanceInMeters: Double {
        distance.converted(to: .meters).value
    }

    var paceInSecondsPerMeter: Double? {
        guard distanceInMeters > 0 else { return nil }
        return elapsedTime / distanceInMeters
    }
}

extension WorkoutMetrics {
    static let zero = WorkoutMetrics()
}
