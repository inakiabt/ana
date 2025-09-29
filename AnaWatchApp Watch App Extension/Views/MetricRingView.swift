import SwiftUI

struct MetricRingView: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var progress: Double = 0.0
    var accent: Color = Color("BrandPrimary")

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color("BrandBackground").opacity(0.6), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [accent, Color("BrandSecondary")]), center: .center),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: progress)
                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 140)

            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
