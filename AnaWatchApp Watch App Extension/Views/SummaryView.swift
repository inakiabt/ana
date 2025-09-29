import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var workoutManager: WorkoutManager
    let summary: WorkoutSummary

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Workout Complete")
                    .font(.headline)
                Text(summary.formattedDuration)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                MetricTile(title: "Distance", value: summary.formattedDistance)
                MetricTile(title: "Calories", value: summary.formattedEnergy)
                MetricTile(title: "Steps", value: stepsDisplay)
                if let average = summary.averageHeartRate {
                    MetricTile(title: "Average HR", value: String(Int(average)), unit: "bpm", footnote: peakHeartRate)
                }
                Button(action: done) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var stepsDisplay: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: summary.steps)) ?? "--"
    }

    private var peakHeartRate: String? {
        guard let peak = summary.peakHeartRate else { return nil }
        return "peak \(Int(peak))"
    }

    private func done() {
        workoutManager.summary = nil
        workoutManager.metrics = WorkoutMetrics()
    }
}
