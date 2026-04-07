import SwiftUI

enum SkillLevel: String, CaseIterable {
    case beginner = "Beginner"
    case someExperience = "Some Experience"
    case intermediate = "Intermediate"

    var description: String {
        switch self {
        case .beginner: "I've never played guitar before"
        case .someExperience: "I know a few chords but want to improve"
        case .intermediate: "I can play songs and want to level up"
        }
    }

    var icon: String {
        switch self {
        case .beginner: "leaf"
        case .someExperience: "flame"
        case .intermediate: "bolt"
        }
    }
}

struct SkillLevelView: View {

    let onSelect: (SkillLevel) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("What's your level?")
                .font(.title)
                .fontWeight(.bold)

            Text("We'll tailor your starting point")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Button {
                        onSelect(level)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: level.icon)
                                .font(.title2)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.rawValue)
                                    .font(.headline)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6).opacity(0.15))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 48)
    }
}
