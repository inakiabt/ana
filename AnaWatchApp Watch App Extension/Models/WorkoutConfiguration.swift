import Foundation

struct WorkoutConfiguration: Codable, Equatable {
    enum SpeedUnit: String, CaseIterable, Codable, Identifiable {
        case milesPerHour
        case kilometersPerHour

        var id: String { rawValue }

        var localizedName: String {
            switch self {
            case .milesPerHour:
                return "mph"
            case .kilometersPerHour:
                return "km/h"
            }
        }

        var unit: UnitSpeed {
            switch self {
            case .milesPerHour:
                return .milesPerHour
            case .kilometersPerHour:
                return .kilometersPerHour
            }
        }
    }

    enum DistanceUnit: String, CaseIterable, Codable, Identifiable {
        case miles
        case kilometers

        var id: String { rawValue }

        var localizedName: String {
            switch self {
            case .miles:
                return "mi"
            case .kilometers:
                return "km"
            }
        }

        var unit: UnitLength {
            switch self {
            case .miles:
                return .miles
            case .kilometers:
                return .kilometers
            }
        }

        var paceUnit: UnitSpeed {
            switch self {
            case .miles:
                return .minutesPerMile
            case .kilometers:
                return .minutesPerKilometer
            }
        }
    }

    var speed: Double
    var incline: Double
    var speedUnit: SpeedUnit
    var distanceUnit: DistanceUnit

    static let `default` = WorkoutConfiguration(speed: 3.0, incline: 0.0, speedUnit: .milesPerHour, distanceUnit: .miles)

    var grade: Double {
        max(incline, 0) / 100.0
    }

    var speedMeasurement: Measurement<UnitSpeed> {
        Measurement(value: speed, unit: speedUnit.unit)
    }

    var speedInMetersPerSecond: Double {
        speedMeasurement.converted(to: .metersPerSecond).value
    }

    mutating func clamp() {
        speed = min(max(speed, 0.5), 12.0)
        incline = min(max(incline, 0.0), 40.0)
    }

    init(speed: Double, incline: Double, speedUnit: SpeedUnit, distanceUnit: DistanceUnit) {
        self.speed = speed
        self.incline = incline
        self.speedUnit = speedUnit
        self.distanceUnit = distanceUnit
    }

    private enum CodingKeys: String, CodingKey {
        case speed
        case incline
        case speedUnit
        case distanceUnit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = WorkoutConfiguration.default

        speed = try container.decodeIfPresent(Double.self, forKey: .speed) ?? fallback.speed
        incline = try container.decodeIfPresent(Double.self, forKey: .incline) ?? fallback.incline
        speedUnit = try container.decodeIfPresent(SpeedUnit.self, forKey: .speedUnit) ?? fallback.speedUnit
        if let decodedDistance = try container.decodeIfPresent(DistanceUnit.self, forKey: .distanceUnit) {
            distanceUnit = decodedDistance
        } else {
            distanceUnit = speedUnit == .kilometersPerHour ? .kilometers : fallback.distanceUnit
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(speed, forKey: .speed)
        try container.encode(incline, forKey: .incline)
        try container.encode(speedUnit, forKey: .speedUnit)
        try container.encode(distanceUnit, forKey: .distanceUnit)
    }
}
