import SwiftUI

/// Shows real-time chord detection feedback.
struct FeedbackOverlay: View {

    let detectedChord: String?
    let expectedChord: String?
    let confidence: Float
    let isCorrect: Bool

    var body: some View {
        Group {
            if let detected = detectedChord {
                HStack(spacing: 12) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(isCorrect ? .green : .red)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(detected)\(isCorrect ? " — Correct!" : " — Try again")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(isCorrect ? .green : .red)

                        Text("Confidence: \(Int(confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isCorrect
                            ? Color.green.opacity(0.12)
                            : Color.red.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isCorrect ? .green : .red, lineWidth: 1)
                        )
                )
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundColor(.gray)

                    Text("Listening... Play the chord")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6).opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isCorrect)
        .animation(.easeInOut(duration: 0.2), value: detectedChord)
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 20) {
        FeedbackOverlay(detectedChord: "G", expectedChord: "G", confidence: 0.92, isCorrect: true)
        FeedbackOverlay(detectedChord: "C", expectedChord: "G", confidence: 0.88, isCorrect: false)
        FeedbackOverlay(detectedChord: nil, expectedChord: "G", confidence: 0, isCorrect: false)
    }
    .padding()
    .background(.black)
}
