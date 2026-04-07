import SwiftUI

/// Displays scrolling guitar tablature with the current chord highlighted.
struct TabScrollView: View {

    let chords: [String]
    let currentIndex: Int

    private let stringNames = ["e", "B", "G", "D", "A", "E"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TAB")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<6, id: \.self) { stringIndex in
                            HStack(spacing: 0) {
                                Text("\(stringNames[stringIndex])|")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)

                                ForEach(Array(chords.enumerated()), id: \.offset) { index, chordName in
                                    let template = ChordLibrary.chord(named: chordName)
                                    let positions = template.map { Array($0.fingerPositions.reversed()) }
                                    let fretNum = positions?[stringIndex] ?? 0
                                    let display = fretNum < 0 ? "x" : "\(fretNum)"
                                    let isCurrent = index == currentIndex

                                    Text("---\(display)------")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(isCurrent ? .green : .gray.opacity(0.5))
                                        .fontWeight(isCurrent ? .bold : .regular)
                                        .id("chord-\(index)-\(stringIndex)")
                                }
                            }
                        }

                        // Chord names row
                        HStack(spacing: 0) {
                            Text("  ")
                                .font(.system(size: 12, design: .monospaced))

                            ForEach(Array(chords.enumerated()), id: \.offset) { index, chordName in
                                let isCurrent = index == currentIndex
                                Text("   \(chordName)       ")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(isCurrent ? .green : .gray.opacity(0.4))
                            }
                        }
                    }
                    .padding(12)
                }
                .background(Color(.systemGray6).opacity(0.15))
                .cornerRadius(8)
                .onChange(of: currentIndex) { _, newIndex in
                    withAnimation {
                        proxy.scrollTo("chord-\(newIndex)-0", anchor: .center)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    TabScrollView(chords: ["G", "C", "Am", "D"], currentIndex: 0)
        .background(.black)
}
