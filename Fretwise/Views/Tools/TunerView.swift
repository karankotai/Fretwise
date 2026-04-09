import SwiftUI

/// The main tuner screen. Composes string indicators, note display,
/// needle gauge, and cents readout.
struct TunerView: View {

    @StateObject private var engine = TunerEngine()

    private var noteDisplay: String {
        engine.nearestGuitarString?.name ?? "—"
    }

    private var centsText: String {
        guard engine.detectedFrequency != nil else { return "" }
        let cents = Int(round(engine.centsOff))
        if cents == 0 { return "In tune" }
        return cents > 0 ? "+\(cents) cents" : "\(cents) cents"
    }

    private var centsColor: Color {
        switch engine.accuracy {
        case .inTune: return .green
        case .close: return .yellow
        case .off: return .red
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // String indicators
                StringIndicatorView(
                    activeStringNumber: engine.nearestGuitarString?.stringNumber,
                    accuracy: engine.accuracy
                )

                Spacer()

                // Note name
                Text(noteDisplay)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Needle gauge
                NeedleGaugeView(
                    centsOffset: engine.centsOff,
                    accuracy: engine.accuracy
                )
                .frame(height: 160)
                .padding(.horizontal, 32)

                // Cents readout
                Text(centsText)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(centsColor)
                    .frame(height: 24)

                // Frequency display
                if let freq = engine.detectedFrequency {
                    Text(String(format: "%.1f Hz", freq))
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                }

                Spacer()

                // Listening indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(engine.detectedFrequency != nil ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(engine.detectedFrequency != nil ? "Listening..." : "Play a string")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            try? engine.start()
        }
        .onDisappear {
            engine.stop()
        }
    }
}

#Preview {
    TunerView()
}
