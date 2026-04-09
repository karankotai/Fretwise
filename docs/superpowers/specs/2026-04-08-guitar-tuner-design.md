# Guitar Tuner — Design Spec

## Overview

A guitar-specific tuner for the Tools tab. Auto-detects which string is being played and shows how sharp/flat it is via a needle gauge. Serves as both a useful tool and a way to verify the audio capture pipeline works on real devices.

## Screen Layout (top to bottom)

1. **String indicators** — a row of 6 circles labeled E A D G B E. The circle closest to the detected pitch lights up with a color based on accuracy: green (in tune, +/- 5 cents), yellow (close, +/- 15 cents), or red (off).
2. **Note display** — large text showing the detected note name (e.g., "A2").
3. **Needle gauge** — semicircular meter. Needle rests at center when perfectly in tune, swings left when flat, right when sharp. The center zone glows green when in tune.
4. **Cents offset** — small text below the gauge showing exact deviation (e.g., "-12 cents" or "+5 cents").

## Audio Pipeline

- Reuse `AudioCaptureService` for microphone input (with `AVAudioSession` configuration).
- New `PitchDetector` class using YIN autocorrelation algorithm — designed for monophonic single-note pitch detection, unlike the chroma/chord pipeline.
- `PitchDetector.detectPitch(buffer:sampleRate:)` returns the fundamental frequency in Hz, or nil if no clear pitch detected.

## Tuning Reference (Standard Tuning)

| String | Note | Frequency (Hz) |
|--------|------|-----------------|
| 6 (low) | E2  | 82.41           |
| 5      | A2   | 110.00          |
| 4      | D3   | 146.83          |
| 3      | G3   | 196.00          |
| 2      | B3   | 246.94          |
| 1 (high) | E4 | 329.63          |

## In-Tune Thresholds

- **Green (in tune):** within +/- 5 cents
- **Yellow (close):** within +/- 15 cents
- **Red (off):** beyond +/- 15 cents

## String Auto-Detection

Map detected frequency to the nearest standard tuning string by finding the string whose reference frequency is closest in cents. Cents formula: `1200 * log2(detected / reference)`.

## Architecture

### New Files

- `Fretwise/Audio/PitchDetector.swift` — YIN autocorrelation pitch detection. Input: `[Float]` buffer + sample rate. Output: `Float?` (Hz) or nil.
- `Fretwise/Audio/TunerEngine.swift` — ObservableObject. Subscribes to `AudioCaptureService.bufferPublisher`, runs `PitchDetector`, maps frequency to nearest string, calculates cents offset. Publishes: `detectedFrequency`, `nearestString`, `centsOffset`, `tuningAccuracy` (enum: inTune/close/off).
- `Fretwise/Views/Tools/TunerView.swift` — Main tuner screen. Composes string indicators, note display, needle gauge, and cents readout.
- `Fretwise/Views/Tools/NeedleGaugeView.swift` — Semicircular gauge drawn with SwiftUI shapes/paths. Needle rotation driven by cents offset.
- `Fretwise/Views/Tools/StringIndicatorView.swift` — Row of 6 labeled circles with color states.

### Modified Files

- `Fretwise/Navigation/AppTabView.swift` — Replace Tools stub with `TunerView`.

### Reused

- `AudioCaptureService` — microphone capture (already has audio session fix).

## Visual Style

- Black background, green accent — consistent with existing practice screen.
- Gauge uses thin white arc with tick marks, green center zone glow.
- Needle is a thin line with a small circle at the pivot point.

## Testing

- Unit test `PitchDetector` with synthetic sine waves at each string frequency.
- Unit test `TunerEngine` cents calculation and string mapping logic.
