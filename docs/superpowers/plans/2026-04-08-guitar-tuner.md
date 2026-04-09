# Guitar Tuner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a guitar tuner in the Tools tab that auto-detects which string is being played and shows how sharp/flat it is via a needle gauge.

**Architecture:** New `PitchDetector` uses YIN autocorrelation to find fundamental frequency from mic audio. `TunerEngine` (ObservableObject) maps frequency to nearest guitar string and calculates cents offset. `TunerView` composes `StringIndicatorView` and `NeedleGaugeView` to display results. Reuses existing `AudioCaptureService` for mic input.

**Tech Stack:** Swift 5.9, SwiftUI, AVFoundation, Accelerate (vDSP)

---

### Task 1: PitchDetector — YIN autocorrelation

**Files:**
- Create: `FretwiseTests/Audio/PitchDetectorTests.swift`
- Create: `Fretwise/Audio/PitchDetector.swift`

- [ ] **Step 1: Write the failing tests**

Create `FretwiseTests/Audio/PitchDetectorTests.swift`:

```swift
import XCTest
@testable import Fretwise

final class PitchDetectorTests: XCTestCase {

    let sampleRate: Float = 44100.0
    let bufferSize = 4096

    private func sineWave(frequency: Float, count: Int, sampleRate: Float) -> [Float] {
        (0..<count).map { i in
            sinf(2.0 * .pi * frequency * Float(i) / sampleRate)
        }
    }

    func testDetectsA440() {
        let detector = PitchDetector()
        let buffer = sineWave(frequency: 440.0, count: bufferSize, sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 440.0, accuracy: 2.0, "Should detect A440 within 2 Hz")
    }

    func testDetectsE2LowString() {
        let detector = PitchDetector()
        let buffer = sineWave(frequency: 82.41, count: bufferSize, sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 82.41, accuracy: 2.0, "Should detect low E string")
    }

    func testDetectsE4HighString() {
        let detector = PitchDetector()
        let buffer = sineWave(frequency: 329.63, count: bufferSize, sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 329.63, accuracy: 2.0, "Should detect high E string")
    }

    func testSilenceReturnsNil() {
        let detector = PitchDetector()
        let buffer = [Float](repeating: 0.0, count: bufferSize)
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNil(result, "Silence should return nil")
    }

    func testVeryQuietSignalReturnsNil() {
        let detector = PitchDetector()
        let buffer = sineWave(frequency: 440.0, count: bufferSize, sampleRate: sampleRate)
            .map { $0 * 0.0001 }
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNil(result, "Very quiet signal should return nil")
    }

    func testDetectsAllGuitarStrings() {
        let detector = PitchDetector()
        let frequencies: [(String, Float)] = [
            ("E2", 82.41), ("A2", 110.0), ("D3", 146.83),
            ("G3", 196.0), ("B3", 246.94), ("E4", 329.63)
        ]

        for (name, freq) in frequencies {
            let buffer = sineWave(frequency: freq, count: bufferSize, sampleRate: sampleRate)
            let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)
            XCTAssertNotNil(result, "\(name) (\(freq) Hz) should be detected")
            XCTAssertEqual(result!, freq, accuracy: 2.0, "\(name) should be within 2 Hz")
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: Open Xcode, run tests (Cmd+U) or `xcodebuild test` targeting `FretwiseTests`.
Expected: Compilation error — `PitchDetector` not defined.

- [ ] **Step 3: Write PitchDetector implementation**

Create `Fretwise/Audio/PitchDetector.swift`:

```swift
import Accelerate
import Foundation

/// Detects the fundamental frequency of a monophonic audio signal
/// using the YIN autocorrelation algorithm.
final class PitchDetector {

    /// Minimum RMS amplitude to consider the signal valid (not silence).
    private let silenceThreshold: Float = 0.01

    /// YIN threshold for periodicity detection. Lower = stricter.
    private let yinThreshold: Float = 0.15

    /// Frequency range for guitar strings (E2=82Hz to E4=330Hz, with margin).
    private let minFrequency: Float = 60.0
    private let maxFrequency: Float = 400.0

    /// Detect the fundamental pitch from a raw audio buffer.
    /// Returns the frequency in Hz, or nil if no clear pitch detected.
    func detectPitch(buffer: [Float], sampleRate: Float) -> Float? {
        // Check signal energy — reject silence
        let rms = sqrt(buffer.map { $0 * $0 }.reduce(0, +) / Float(buffer.count))
        guard rms > silenceThreshold else { return nil }

        let halfN = buffer.count / 2
        let minLag = Int(sampleRate / maxFrequency)
        let maxLag = min(Int(sampleRate / minFrequency), halfN)

        guard minLag < maxLag else { return nil }

        // Step 1: Compute difference function d(tau)
        var difference = [Float](repeating: 0, count: halfN)

        for tau in minLag..<maxLag {
            var sum: Float = 0
            for j in 0..<halfN {
                let delta = buffer[j] - buffer[j + tau]
                sum += delta * delta
            }
            difference[tau] = sum
        }

        // Step 2: Cumulative mean normalized difference (CMND)
        var cmnd = [Float](repeating: 0, count: halfN)
        cmnd[0] = 1.0
        var runningSum: Float = 0

        for tau in 1..<maxLag {
            runningSum += difference[tau]
            cmnd[tau] = runningSum > 0 ? difference[tau] * Float(tau) / runningSum : 1.0
        }

        // Step 3: Find the first tau where CMND dips below threshold,
        // then pick the minimum in that valley.
        var bestTau: Int?

        for tau in minLag..<maxLag {
            if cmnd[tau] < yinThreshold {
                // Find the local minimum in this dip
                var localMin = tau
                while localMin + 1 < maxLag && cmnd[localMin + 1] < cmnd[localMin] {
                    localMin += 1
                }
                bestTau = localMin
                break
            }
        }

        guard let tau = bestTau else { return nil }

        // Step 4: Parabolic interpolation for sub-sample accuracy
        let s0 = cmnd[tau - 1]
        let s1 = cmnd[tau]
        let s2 = tau + 1 < halfN ? cmnd[tau + 1] : s1

        let adjustment = (s0 - s2) / (2.0 * (s0 - 2.0 * s1 + s2))
        let refinedTau = Float(tau) + (adjustment.isFinite ? adjustment : 0)

        guard refinedTau > 0 else { return nil }

        return sampleRate / refinedTau
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: Open Xcode, run `PitchDetectorTests` (Cmd+U).
Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Fretwise/Audio/PitchDetector.swift FretwiseTests/Audio/PitchDetectorTests.swift
git commit -m "feat(tuner): add PitchDetector with YIN autocorrelation"
```

---

### Task 2: TunerEngine — frequency-to-string mapping and cents calculation

**Files:**
- Create: `FretwiseTests/Audio/TunerEngineTests.swift`
- Create: `Fretwise/Audio/TunerEngine.swift`

- [ ] **Step 1: Write the failing tests**

Create `FretwiseTests/Audio/TunerEngineTests.swift`:

```swift
import XCTest
@testable import Fretwise

final class TunerEngineTests: XCTestCase {

    func testCentsCalculationPerfectPitch() {
        let cents = TunerEngine.centsOffset(detected: 110.0, reference: 110.0)
        XCTAssertEqual(cents, 0.0, accuracy: 0.01)
    }

    func testCentsCalculationSharp() {
        // One semitone sharp (A2 -> A#2)
        let cents = TunerEngine.centsOffset(detected: 116.54, reference: 110.0)
        XCTAssertEqual(cents, 100.0, accuracy: 1.0)
    }

    func testCentsCalculationFlat() {
        // 50 cents flat
        let freqFlat = 110.0 * powf(2.0, -50.0 / 1200.0)
        let cents = TunerEngine.centsOffset(detected: freqFlat, reference: 110.0)
        XCTAssertEqual(cents, -50.0, accuracy: 1.0)
    }

    func testNearestStringE2() {
        let string = TunerEngine.nearestString(to: 83.0)
        XCTAssertEqual(string.name, "E2")
        XCTAssertEqual(string.frequency, 82.41, accuracy: 0.01)
    }

    func testNearestStringA2() {
        let string = TunerEngine.nearestString(to: 112.0)
        XCTAssertEqual(string.name, "A2")
    }

    func testNearestStringD3() {
        let string = TunerEngine.nearestString(to: 145.0)
        XCTAssertEqual(string.name, "D3")
    }

    func testNearestStringG3() {
        let string = TunerEngine.nearestString(to: 200.0)
        XCTAssertEqual(string.name, "G3")
    }

    func testNearestStringB3() {
        let string = TunerEngine.nearestString(to: 250.0)
        XCTAssertEqual(string.name, "B3")
    }

    func testNearestStringE4() {
        let string = TunerEngine.nearestString(to: 330.0)
        XCTAssertEqual(string.name, "E4")
    }

    func testTuningAccuracyInTune() {
        let accuracy = TunerEngine.tuningAccuracy(centsOffset: 3.0)
        XCTAssertEqual(accuracy, .inTune)
    }

    func testTuningAccuracyClose() {
        let accuracy = TunerEngine.tuningAccuracy(centsOffset: 10.0)
        XCTAssertEqual(accuracy, .close)
    }

    func testTuningAccuracyOff() {
        let accuracy = TunerEngine.tuningAccuracy(centsOffset: -20.0)
        XCTAssertEqual(accuracy, .off)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: Open Xcode, run `TunerEngineTests`.
Expected: Compilation error — `TunerEngine` not defined.

- [ ] **Step 3: Write TunerEngine implementation**

Create `Fretwise/Audio/TunerEngine.swift`:

```swift
import Combine
import Foundation

/// Represents a guitar string with its standard tuning frequency.
struct GuitarString: Equatable {
    let name: String
    let frequency: Float
    let stringNumber: Int  // 6 = low E, 1 = high E
}

/// How close the tuning is to the target.
enum TuningAccuracy: Equatable {
    case inTune   // within +/- 5 cents
    case close    // within +/- 15 cents
    case off      // beyond +/- 15 cents
}

/// Orchestrates pitch detection and maps results to guitar strings.
/// Publishes tuning state for the UI.
final class TunerEngine: ObservableObject {

    @Published var detectedFrequency: Float?
    @Published var nearestGuitarString: GuitarString?
    @Published var centsOff: Float = 0
    @Published var accuracy: TuningAccuracy = .off

    static let standardTuning: [GuitarString] = [
        GuitarString(name: "E2", frequency: 82.41,  stringNumber: 6),
        GuitarString(name: "A2", frequency: 110.00, stringNumber: 5),
        GuitarString(name: "D3", frequency: 146.83, stringNumber: 4),
        GuitarString(name: "G3", frequency: 196.00, stringNumber: 3),
        GuitarString(name: "B3", frequency: 246.94, stringNumber: 2),
        GuitarString(name: "E4", frequency: 329.63, stringNumber: 1),
    ]

    private let audioCapture: AudioCaptureService
    private let pitchDetector = PitchDetector()
    private var cancellables = Set<AnyCancellable>()

    init(audioCapture: AudioCaptureService = AudioCaptureService()) {
        self.audioCapture = audioCapture

        audioCapture.bufferPublisher
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] buffer in
                self?.processBuffer(buffer)
            }
            .store(in: &cancellables)
    }

    func start() throws {
        try audioCapture.start()
    }

    func stop() {
        audioCapture.stop()
        DispatchQueue.main.async {
            self.detectedFrequency = nil
            self.nearestGuitarString = nil
            self.centsOff = 0
            self.accuracy = .off
        }
    }

    var permissionGranted: Bool {
        audioCapture.permissionGranted
    }

    private func processBuffer(_ buffer: [Float]) {
        let sampleRate = audioCapture.actualSampleRate
        guard let frequency = pitchDetector.detectPitch(buffer: buffer, sampleRate: sampleRate) else {
            DispatchQueue.main.async { [weak self] in
                self?.detectedFrequency = nil
                self?.nearestGuitarString = nil
            }
            return
        }

        let nearest = TunerEngine.nearestString(to: frequency)
        let cents = TunerEngine.centsOffset(detected: frequency, reference: nearest.frequency)
        let acc = TunerEngine.tuningAccuracy(centsOffset: cents)

        DispatchQueue.main.async { [weak self] in
            self?.detectedFrequency = frequency
            self?.nearestGuitarString = nearest
            self?.centsOff = cents
            self?.accuracy = acc
        }
    }

    // MARK: - Static helpers (public for testing)

    static func centsOffset(detected: Float, reference: Float) -> Float {
        1200.0 * log2(detected / reference)
    }

    static func nearestString(to frequency: Float) -> GuitarString {
        standardTuning.min(by: {
            abs(centsOffset(detected: frequency, reference: $0.frequency)) <
            abs(centsOffset(detected: frequency, reference: $1.frequency))
        })!
    }

    static func tuningAccuracy(centsOffset: Float) -> TuningAccuracy {
        let absCents = abs(centsOffset)
        if absCents <= 5.0 { return .inTune }
        if absCents <= 15.0 { return .close }
        return .off
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: Open Xcode, run `TunerEngineTests`.
Expected: All 12 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Fretwise/Audio/TunerEngine.swift FretwiseTests/Audio/TunerEngineTests.swift
git commit -m "feat(tuner): add TunerEngine with string mapping and cents calculation"
```

---

### Task 3: NeedleGaugeView — semicircular tuner gauge

**Files:**
- Create: `Fretwise/Views/Tools/NeedleGaugeView.swift`

- [ ] **Step 1: Create the gauge view**

Create `Fretwise/Views/Tools/NeedleGaugeView.swift`:

```swift
import SwiftUI

/// A semicircular gauge that shows how sharp or flat the tuning is.
/// Needle points straight up when perfectly in tune.
struct NeedleGaugeView: View {

    /// Cents offset from the target pitch. Negative = flat, positive = sharp.
    let centsOffset: Float

    /// Current tuning accuracy for color coding.
    let accuracy: TuningAccuracy

    /// The needle angle in degrees. -50 cents maps to -90 deg, +50 maps to +90 deg.
    private var needleAngle: Double {
        let clamped = max(-50, min(50, Double(centsOffset)))
        return clamped * 90.0 / 50.0
    }

    private var accentColor: Color {
        switch accuracy {
        case .inTune: return .green
        case .close: return .yellow
        case .off: return .red
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height * 2)
            let radius = size / 2 - 20
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)

            ZStack {
                // Outer arc
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(0),
                        clockwise: false
                    )
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)

                // Tick marks
                ForEach(-5...5, id: \.self) { tick in
                    let angle = Angle.degrees(180.0 + Double(tick) * 18.0)
                    let isMajor = tick % 5 == 0 || tick == 0
                    let innerR = radius - (isMajor ? 16 : 10)
                    let outerR = radius

                    Path { path in
                        path.move(to: pointOnArc(center: center, radius: innerR, angle: angle))
                        path.addLine(to: pointOnArc(center: center, radius: outerR, angle: angle))
                    }
                    .stroke(tick == 0 ? Color.green : Color.gray.opacity(0.5),
                            lineWidth: isMajor ? 2 : 1)
                }

                // Green center glow
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius - 8,
                        startAngle: .degrees(180 + 72),  // ~-10 degrees from center
                        endAngle: .degrees(180 + 108),   // ~+10 degrees from center
                        clockwise: false
                    )
                }
                .stroke(Color.green.opacity(accuracy == .inTune ? 0.8 : 0.2), lineWidth: 4)

                // Flat / Sharp labels
                Text("♭")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .position(
                        x: center.x - radius + 10,
                        y: center.y - 10
                    )

                Text("♯")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .position(
                        x: center.x + radius - 10,
                        y: center.y - 10
                    )

                // Needle
                let needleLength = radius - 24
                let needleEnd = pointOnArc(
                    center: center,
                    radius: needleLength,
                    angle: .degrees(270 + needleAngle)
                )

                Path { path in
                    path.move(to: center)
                    path.addLine(to: needleEnd)
                }
                .stroke(accentColor, lineWidth: 2.5)

                // Pivot circle
                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)
                    .position(center)
            }
        }
        .aspectRatio(2.0, contentMode: .fit)
        .animation(.easeOut(duration: 0.15), value: centsOffset)
    }

    private func pointOnArc(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + CGFloat(cos(angle.radians)) * radius,
            y: center.y + CGFloat(sin(angle.radians)) * radius
        )
    }
}

#Preview {
    VStack(spacing: 40) {
        NeedleGaugeView(centsOffset: 0, accuracy: .inTune)
        NeedleGaugeView(centsOffset: -12, accuracy: .close)
        NeedleGaugeView(centsOffset: 30, accuracy: .off)
    }
    .padding()
    .background(.black)
}
```

- [ ] **Step 2: Verify preview renders in Xcode**

Open `NeedleGaugeView.swift` in Xcode and check the SwiftUI preview (Cmd+Option+P). All three states (in tune, close, off) should render with correct needle positions.

- [ ] **Step 3: Commit**

```bash
git add Fretwise/Views/Tools/NeedleGaugeView.swift
git commit -m "feat(tuner): add NeedleGaugeView semicircular gauge"
```

---

### Task 4: StringIndicatorView — string selection row

**Files:**
- Create: `Fretwise/Views/Tools/StringIndicatorView.swift`

- [ ] **Step 1: Create the string indicator view**

Create `Fretwise/Views/Tools/StringIndicatorView.swift`:

```swift
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
```

- [ ] **Step 2: Verify preview renders in Xcode**

Open `StringIndicatorView.swift` in Xcode and check the SwiftUI preview. Should show three rows: one with E2 highlighted green, one with B3 highlighted yellow, one with no active string.

- [ ] **Step 3: Commit**

```bash
git add Fretwise/Views/Tools/StringIndicatorView.swift
git commit -m "feat(tuner): add StringIndicatorView string selection row"
```

---

### Task 5: TunerView — main tuner screen

**Files:**
- Create: `Fretwise/Views/Tools/TunerView.swift`
- Modify: `Fretwise/Navigation/AppTabView.swift`

- [ ] **Step 1: Create the main tuner view**

Create `Fretwise/Views/Tools/TunerView.swift`:

```swift
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
```

- [ ] **Step 2: Wire TunerView into the Tools tab**

In `Fretwise/Navigation/AppTabView.swift`, replace:

```swift
Text("Tools — Coming Soon")
    .tabItem {
        Label("Tools", systemImage: "wrench.and.screwdriver")
    }
```

with:

```swift
TunerView()
    .tabItem {
        Label("Tuner", systemImage: "tuningfork")
    }
```

- [ ] **Step 3: Build and verify in Xcode**

Build the project (Cmd+B). Navigate to the Tuner tab in the preview or simulator. The UI should render with "—" note display and "Play a string" indicator.

- [ ] **Step 4: Commit**

```bash
git add Fretwise/Views/Tools/TunerView.swift Fretwise/Navigation/AppTabView.swift
git commit -m "feat(tuner): add TunerView and wire into Tools tab"
```

---

### Task 6: Regenerate Xcode project

**Files:**
- Modify: `Fretwise.xcodeproj/project.pbxproj` (generated)

- [ ] **Step 1: Regenerate with XcodeGen**

Since the project uses `project.yml` with `sources: - path: Fretwise`, new files under `Fretwise/` should be picked up automatically. Run:

```bash
xcodegen generate
```

If XcodeGen is not installed or the project doesn't auto-detect new files, manually add the new files in Xcode:
- `Fretwise/Audio/PitchDetector.swift`
- `Fretwise/Audio/TunerEngine.swift`
- `Fretwise/Views/Tools/TunerView.swift`
- `Fretwise/Views/Tools/NeedleGaugeView.swift`
- `Fretwise/Views/Tools/StringIndicatorView.swift`
- `FretwiseTests/Audio/PitchDetectorTests.swift`
- `FretwiseTests/Audio/TunerEngineTests.swift`

- [ ] **Step 2: Build and run all tests**

Build (Cmd+B), then run all tests (Cmd+U). All existing tests plus the new `PitchDetectorTests` and `TunerEngineTests` should pass.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: regenerate Xcode project with tuner files"
```

---

### Task 7: Test on device

- [ ] **Step 1: Run on physical device**

Connect your iPhone, select it as the build target, and run (Cmd+R). Navigate to the Tuner tab. Play each open string on your guitar and verify:
- The correct string lights up in the indicator row
- The needle gauge responds to pitch
- The cents readout shows meaningful values
- The note name updates

This also validates that the `AVAudioSession` fix from earlier is working.

- [ ] **Step 2: Note any issues for follow-up**

If detection is unreliable, the YIN threshold (0.15) or silence threshold (0.01) may need adjustment for real-world audio. These are tunable constants in `PitchDetector.swift`.
