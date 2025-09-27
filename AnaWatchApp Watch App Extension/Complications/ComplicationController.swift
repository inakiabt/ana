import ClockKit
import SwiftUI
import UIKit

final class ComplicationController: NSObject, CLKComplicationDataSource {
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptor = CLKComplicationDescriptor(
            identifier: "anaComplication",
            displayName: "Ana Treadmill",
            supportedFamilies: [.circularSmall, .utilitarianSmall, .utilitarianLarge, .graphicCircular, .graphicRectangular, .graphicCorner, .graphicBezel]
        )
        handler([descriptor])
    }

    func getCurrentTimelineEntry(for complication: CLKComplication, with handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let summary = AnaStorage.loadSummary() ?? placeholderSummary
        handler(entry(for: complication, summary: summary))
    }

    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, with handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler([])
    }

    func getTimelineStartDate(for complication: CLKComplication, with handler: @escaping (Date?) -> Void) {
        handler(nil)
    }

    func getTimelineEndDate(for complication: CLKComplication, with handler: @escaping (Date?) -> Void) {
        handler(nil)
    }

    func getSupportedTimeTravelDirections(for complication: CLKComplication, with handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }

    func getPrivacyBehavior(for complication: CLKComplication, with handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    func getPlaceholderTemplate(for complication: CLKComplication, with handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(template(for: complication, summary: placeholderSummary))
    }

    private func entry(for complication: CLKComplication, summary: WorkoutSummary) -> CLKComplicationTimelineEntry? {
        guard let template = template(for: complication, summary: summary) else { return nil }
        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }

    private func template(for complication: CLKComplication, summary: WorkoutSummary) -> CLKComplicationTemplate? {
        switch complication.family {
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: heartRateText(from: summary))
            template.fillFraction = Float(heartRateFraction(from: summary))
            template.ringStyle = .closed
            return template
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.textProvider = CLKSimpleTextProvider(text: "\(Int(summary.activeEnergy)) kcal")
            return template
        case .utilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "Ana: \(distanceText(from: summary)) in \(summary.formattedDuration)")
            return template
        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            template.centerTextProvider = CLKSimpleTextProvider(text: heartRateText(from: summary))
            template.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: UIColor(named: "BrandPrimary") ?? .systemGreen, fillFraction: heartRateFraction(from: summary))
            return template
        case .graphicRectangular:
            let template = CLKComplicationTemplateGraphicRectangularStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Ana Treadmill")
            template.body1TextProvider = CLKSimpleTextProvider(text: "Distance: \(distanceText(from: summary))")
            template.body2TextProvider = CLKSimpleTextProvider(text: "Avg HR: \(heartRateText(from: summary)) • \(summary.formattedDuration)")
            return template
        case .graphicCorner:
            let gauge = CLKSimpleGaugeProvider(style: .fill, gaugeColor: UIColor(named: "BrandSecondary") ?? .systemTeal, fillFraction: heartRateFraction(from: summary))
            let template = CLKComplicationTemplateGraphicCornerGaugeText()
            template.outerTextProvider = CLKSimpleTextProvider(text: "\(Int(summary.activeEnergy)) kcal")
            template.gaugeProvider = gauge
            template.leadingTextProvider = CLKSimpleTextProvider(text: heartRateText(from: summary))
            return template
        case .graphicBezel:
            let circular = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            circular.centerTextProvider = CLKSimpleTextProvider(text: heartRateText(from: summary))
            circular.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: UIColor(named: "BrandPrimary") ?? .systemGreen, fillFraction: heartRateFraction(from: summary))
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            template.circularTemplate = circular
            template.textProvider = CLKSimpleTextProvider(text: "Ana • \(distanceText(from: summary))")
            return template
        default:
            return nil
        }
    }

    private func heartRateText(from summary: WorkoutSummary) -> String {
        if let average = summary.averageHeartRate {
            return "\(Int(average))"
        }
        return "--"
    }

    private func heartRateFraction(from summary: WorkoutSummary) -> Double {
        guard let average = summary.averageHeartRate else { return 0.2 }
        return min(max(average / 190.0, 0.1), 1.0)
    }

    private func distanceText(from summary: WorkoutSummary) -> String {
        MeasurementFormatter.string(from: summary.distance, convertedTo: summary.configuration.distanceUnit.unit)
    }

    private var placeholderSummary: WorkoutSummary {
        WorkoutSummary(
            start: Date().addingTimeInterval(-1800),
            end: Date(),
            duration: 1800,
            distance: Measurement(value: 2500, unit: UnitLength.meters),
            steps: 3200,
            averageHeartRate: 132,
            activeEnergy: 220,
            configuration: .default,
            peakHeartRate: 158
        )
    }
}
