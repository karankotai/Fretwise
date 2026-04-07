import SwiftUI

/// Draws an interactive fretboard showing chord finger positions.
/// Finger dots animate with spring transitions when the chord changes.
struct FretboardView: View {

    let chord: ChordTemplate?
    let isCorrect: Bool

    private let fretCount = 4
    private let stringCount = 6
    private let stringLabels = ["E", "B", "G", "D", "A", "E"]

    private var dotColor: Color {
        isCorrect ? .green : .teal
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let leftPadding: CGFloat = 40
            let rightPadding: CGFloat = 16
            let topPadding: CGFloat = 20
            let bottomPadding: CGFloat = 30
            let fretboardWidth = width - leftPadding - rightPadding
            let fretboardHeight = height - topPadding - bottomPadding
            let stringSpacing = fretboardHeight / CGFloat(stringCount - 1)
            let fretSpacing = fretboardWidth / CGFloat(fretCount)

            ZStack(alignment: .topLeading) {
                // Fretboard background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.1, green: 0.08, blue: 0.06))
                    .padding(.leading, leftPadding)
                    .padding(.trailing, rightPadding)
                    .padding(.top, topPadding)
                    .padding(.bottom, bottomPadding)

                // Nut
                Rectangle()
                    .fill(.white.opacity(0.8))
                    .frame(width: 4)
                    .offset(x: leftPadding, y: topPadding)
                    .frame(height: fretboardHeight)

                // Fret lines
                ForEach(1...fretCount, id: \.self) { fret in
                    Rectangle()
                        .fill(.gray.opacity(0.4))
                        .frame(width: 2)
                        .offset(
                            x: leftPadding + CGFloat(fret) * fretSpacing,
                            y: topPadding
                        )
                        .frame(height: fretboardHeight)
                }

                // Strings
                ForEach(0..<stringCount, id: \.self) { string in
                    let thickness: CGFloat = CGFloat(string + 1) * 0.4 + 0.6
                    Rectangle()
                        .fill(.gray.opacity(0.6))
                        .frame(height: thickness)
                        .offset(
                            x: leftPadding,
                            y: topPadding + CGFloat(string) * stringSpacing
                        )
                        .frame(width: fretboardWidth)
                }

                // String labels
                ForEach(0..<stringCount, id: \.self) { string in
                    Text(stringLabels[string])
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .position(
                            x: leftPadding / 2,
                            y: topPadding + CGFloat(string) * stringSpacing
                        )
                }

                // Fret numbers
                ForEach(1...fretCount, id: \.self) { fret in
                    Text("\(fret)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                        .position(
                            x: leftPadding + (CGFloat(fret) - 0.5) * fretSpacing,
                            y: height - bottomPadding / 2
                        )
                }

                // Finger dots
                if let chord {
                    let displayPositions = Array(chord.fingerPositions.reversed())
                    let displayFingers = Array(chord.fingerNumbers.reversed())

                    ForEach(0..<stringCount, id: \.self) { displayString in
                        let fret = displayPositions[displayString]
                        let finger = displayFingers[displayString]

                        if fret > 0 {
                            Circle()
                                .fill(dotColor)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("\(finger)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                )
                                .position(
                                    x: leftPadding + (CGFloat(fret) - 0.5) * fretSpacing,
                                    y: topPadding + CGFloat(displayString) * stringSpacing
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: chord.name)
                        } else if fret == 0 {
                            Circle()
                                .stroke(dotColor, lineWidth: 2)
                                .frame(width: 14, height: 14)
                                .position(
                                    x: leftPadding - 14,
                                    y: topPadding + CGFloat(displayString) * stringSpacing
                                )
                        } else {
                            Text("\u{2715}")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red.opacity(0.6))
                                .position(
                                    x: leftPadding - 14,
                                    y: topPadding + CGFloat(displayString) * stringSpacing
                                )
                        }
                    }
                }
            }
        }
        .aspectRatio(2.2, contentMode: .fit)
    }
}

#Preview {
    FretboardView(chord: ChordLibrary.gMajor, isCorrect: true)
        .padding()
        .background(.black)
}
