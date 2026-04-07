import SwiftUI

/// Displays the target chord name, instruction, and lesson progress.
struct TargetChordHeader: View {

    let chordName: String
    let instruction: String
    let stepIndex: Int
    let totalSteps: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Step \(stepIndex + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Text(chordName)
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundColor(.green)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: chordName)

            Text(instruction)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    TargetChordHeader(
        chordName: "G Major",
        instruction: "Strum all 6 strings",
        stepIndex: 0,
        totalSteps: 4
    )
    .background(.black)
}
