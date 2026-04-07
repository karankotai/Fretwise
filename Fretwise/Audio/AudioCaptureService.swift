import AVFoundation
import Combine
import Foundation

/// Captures audio from the device microphone via AVAudioEngine.
/// Publishes raw Float buffers for processing.
final class AudioCaptureService: ObservableObject {

    /// Published audio buffers (4096 samples each).
    let bufferPublisher = PassthroughSubject<[Float], Never>()

    @Published var isRunning = false
    @Published var permissionGranted = false

    private let engine = AVAudioEngine()
    private let bufferSize: AVAudioFrameCount = 4096

    init() {
        checkPermission()
    }

    func checkPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            permissionGranted = true
        case .denied:
            permissionGranted = false
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                }
            }
        @unknown default:
            permissionGranted = false
        }
    }

    func start() throws {
        guard permissionGranted else { return }
        guard !isRunning else { return }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Guard against invalid format (e.g., iOS Simulator with no mic)
        guard format.sampleRate > 0 && format.channelCount > 0 else {
            print("[AudioCaptureService] No valid audio input (simulator?). Skipping mic capture.")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) {
            [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
            self?.bufferPublisher.send(samples)
        }

        engine.prepare()
        try engine.start()

        DispatchQueue.main.async {
            self.isRunning = true
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        DispatchQueue.main.async {
            self.isRunning = false
        }
    }
}
