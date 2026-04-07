import SwiftUI

struct WelcomeView: View {

    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "guitars.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)

            Text("Fretwise")
                .font(.system(size: 40, weight: .heavy, design: .rounded))

            Text("Your guitar learning companion.\nLearn chords, play songs, track progress.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}
