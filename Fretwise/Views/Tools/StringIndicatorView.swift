import SwiftUI

/// Row of 6 circles representing guitar strings.
/// The active string lights up with a color reflecting tuning accuracy.
struct StringIndicatorView: View {

    /// The currently detected string (by stringNumber), or nil if none.
    let activeStringNumber: Int?

    /// Tuning accuracy for the active string.
    let accuracy: TuningAccuracy

    private let strings = TunerEngine.standardTuning

    private func color(for string: GuitarString) -> Color {
        guard string.stringNumber == activeStringNumber else {
            return .gray.opacity(0.3)
        }
        switch accuracy {
        case .inTune: return .green
        case .close: return .yellow
        case .off: return .red
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(strings, id: \.stringNumber) { string in
                VStack(spacing: 6) {
                    Circle()
                        .fill(color(for: string))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(string.name.prefix(string.name.count - 1)))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(
                                    string.stringNumber == activeStringNumber ? .black : .gray
                                )
                        )

                    Text(string.name)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(
                            string.stringNumber == activeStringNumber ? .white : .gray.opacity(0.5)
                        )
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: activeStringNumber)
    }
}

#Preview {
    VStack(spacing: 30) {
        StringIndicatorView(activeStringNumber: 6, accuracy: .inTune)
        StringIndicatorView(activeStringNumber: 2, accuracy: .close)
        StringIndicatorView(activeStringNumber: nil, accuracy: .off)
    }
    .padding()
    .background(.black)
}
