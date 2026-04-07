import AVFoundation
import SwiftUI

struct MicPermissionView: View {

    let onContinue: () -> Void
    @State private var permissionStatus: AVAudioApplication.recordPermission = .undetermined

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)

            Text("Microphone Access")
                .font(.title)
                .fontWeight(.bold)

            Text("Fretwise listens to your guitar to detect chords and give you real-time feedback as you practice.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            if permissionStatus == .granted {
                Label("Microphone enabled", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
            }

            Button(action: requestPermission) {
                Text(permissionStatus == .granted ? "Continue" : "Enable Microphone")
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
        .onAppear {
            permissionStatus = AVAudioApplication.shared.recordPermission
        }
    }

    private func requestPermission() {
        if permissionStatus == .granted {
            onContinue()
            return
        }

        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                permissionStatus = granted ? .granted : .denied
                if granted {
                    onContinue()
                }
            }
        }
    }
}
