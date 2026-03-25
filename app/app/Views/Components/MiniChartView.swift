import SwiftUI

struct MiniChartView: View {
    let values: [Double]
    let targetValue: Double?
    let color: Color
    var height: CGFloat = 80

    private var maxVal: Double {
        max(values.max() ?? 1, targetValue ?? 1, 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Target line
                if let target = targetValue {
                    let y = geo.size.height * (1 - target / maxVal)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(Theme.Colors.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                // Line chart
                if values.count > 1 {
                    let stepX = geo.size.width / CGFloat(values.count - 1)

                    // Fill area
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geo.size.height))
                        for (i, val) in values.enumerated() {
                            let x = stepX * CGFloat(i)
                            let y = geo.size.height * (1 - val / maxVal)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Stroke line
                    Path { path in
                        for (i, val) in values.enumerated() {
                            let x = stepX * CGFloat(i)
                            let y = geo.size.height * (1 - val / maxVal)
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .frame(height: height)
    }
}

// Mini sparkline for compact usage
struct SparklineView: View {
    let values: [Double]
    let color: Color
    var height: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            if values.count > 1 {
                let maxVal = max(values.max() ?? 1, 1)
                let stepX = geo.size.width / CGFloat(values.count - 1)

                Path { path in
                    for (i, val) in values.enumerated() {
                        let x = stepX * CGFloat(i)
                        let y = geo.size.height * (1 - val / maxVal)
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
    }
}
