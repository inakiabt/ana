import Foundation

extension DateComponentsFormatter {
    static let workout: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
}

extension MeasurementFormatter {
    static let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit]
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter
    }()

    static let paceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit]
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter
    }()

    static let kilocalorieFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = [.providedUnit]
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    static func string(from distance: Measurement<UnitLength>, convertedTo unit: UnitLength) -> String {
        let converted = distance.converted(to: unit)
        return MeasurementFormatter.distanceFormatter.string(from: converted)
    }

    static func string(from pace: Measurement<UnitSpeed>, convertedTo unit: UnitSpeed) -> String {
        let converted = pace.converted(to: unit)
        return MeasurementFormatter.paceFormatter.string(from: converted)
    }
}

extension TimeInterval {
    var formattedElapsed: String {
        DateComponentsFormatter.workout.string(from: self) ?? "--"
    }
}
