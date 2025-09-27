import Foundation

struct UserProfile: Codable, Equatable {
    enum Gender: String, Codable, CaseIterable, Identifiable {
        case female
        case male
        case nonBinary
        case unspecified

        var id: String { rawValue }

        var localizedName: String {
            switch self {
            case .female:
                return "Female"
            case .male:
                return "Male"
            case .nonBinary:
                return "Non-binary"
            case .unspecified:
                return "Unspecified"
            }
        }

        var stepLengthMultiplier: Double {
            switch self {
            case .female:
                return 0.413
            case .male:
                return 0.415
            case .nonBinary:
                return 0.414
            case .unspecified:
                return 0.414
            }
        }
    }

    var heightInMeters: Double?
    var weightInKilograms: Double?
    var restingHeartRate: Double?
    var gender: Gender?
    var stepLengthInMeters: Double?

    static let `default` = UserProfile(
        heightInMeters: nil,
        weightInKilograms: 72.0,
        restingHeartRate: 60,
        gender: nil,
        stepLengthInMeters: nil
    )

    var height: Measurement<UnitLength>? {
        guard let heightInMeters else { return nil }
        return Measurement(value: heightInMeters, unit: .meters)
    }

    var weight: Measurement<UnitMass>? {
        guard let weightInKilograms else { return nil }
        return Measurement(value: weightInKilograms, unit: .kilograms)
    }

    private var fallbackStepLength: Double { 0.75 }

    var estimatedStepLength: Double {
        guard let heightInMeters, heightInMeters > 0 else { return fallbackStepLength }
        let multiplier = gender?.stepLengthMultiplier ?? Gender.unspecified.stepLengthMultiplier
        return heightInMeters * multiplier
    }

    var resolvedStepLength: Double {
        let value = stepLengthInMeters ?? estimatedStepLength
        return min(max(value, 0.35), 1.5)
    }

    var stepLengthMeasurement: Measurement<UnitLength> {
        Measurement(value: resolvedStepLength, unit: .meters)
    }

    var estimatedStrideLength: Double {
        resolvedStepLength * 2.0
    }

    var usingEstimatedStepLength: Bool {
        stepLengthInMeters == nil
    }
}
