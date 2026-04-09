import SwiftUI

/// A semicircular gauge that shows how sharp or flat the tuning is.
/// Needle points straight up when perfectly in tune.
struct NeedleGaugeView: View {

    /// Cents offset from the target pitch. Negative = flat, positive = sharp.
    let centsOffset: Float

    /// Current tuning accuracy for color coding.
    let accuracy: TuningAccuracy

    /// The needle angle in degrees. -50 cents maps to -90 deg, +50 maps to +90 deg.
    private var needleAngle: Double {
        let clamped = max(-50, min(50, Double(centsOffset)))
        return clamped * 90.0 / 50.0
    }

    private var accentColor: Color {
        switch accuracy {
        case .inTune: return .green
        case .close: return .yellow
        case .off: return .red
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height * 2)
            let radius = size / 2 - 20
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)

            ZStack {
                // Outer arc
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(0),
                        clockwise: false
                    )
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)

                // Tick marks
                ForEach(-5...5, id: \.self) { tick in
                    let angle = Angle.degrees(180.0 + Double(tick) * 18.0)
                    let isMajor = tick % 5 == 0 || tick == 0
                    let innerR = radius - (isMajor ? 16 : 10)
                    let outerR = radius

                    Path { path in
                        path.move(to: pointOnArc(center: center, radius: innerR, angle: angle))
                        path.addLine(to: pointOnArc(center: center, radius: outerR, angle: angle))
                    }
                    .stroke(tick == 0 ? Color.green : Color.gray.opacity(0.5),
                            lineWidth: isMajor ? 2 : 1)
                }

                // Green center glow
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius - 8,
                        startAngle: .degrees(180 + 72),
                        endAngle: .degrees(180 + 108),
                        clockwise: false
                    )
                }
                .stroke(Color.green.opacity(accuracy == .inTune ? 0.8 : 0.2), lineWidth: 4)

                // Flat / Sharp labels
                Text("♭")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .position(
                        x: center.x - radius + 10,
                        y: center.y - 10
                    )

                Text("♯")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .position(
                        x: center.x + radius - 10,
                        y: center.y - 10
                    )

                // Needle
                let needleLength = radius - 24
                let needleEnd = pointOnArc(
                    center: center,
                    radius: needleLength,
                    angle: .degrees(270 + needleAngle)
                )

                Path { path in
                    path.move(to: center)
                    path.addLine(to: needleEnd)
                }
                .stroke(accentColor, lineWidth: 2.5)

                // Pivot circle
                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)
                    .position(center)
            }
        }
        .aspectRatio(2.0, contentMode: .fit)
        .animation(.easeOut(duration: 0.15), value: centsOffset)
    }

    private func pointOnArc(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + CGFloat(cos(angle.radians)) * radius,
            y: center.y + CGFloat(sin(angle.radians)) * radius
        )
    }
}

#Preview {
    VStack(spacing: 40) {
        NeedleGaugeView(centsOffset: 0, accuracy: .inTune)
        NeedleGaugeView(centsOffset: -12, accuracy: .close)
        NeedleGaugeView(centsOffset: 30, accuracy: .off)
    }
    .padding()
    .background(.black)
}
