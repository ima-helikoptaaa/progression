import CoreHaptics
import UIKit

class ProgressiveHapticEngine {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private var supportsHaptics: Bool

    init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if supportsHaptics {
            prepareEngine()
        }
    }

    private func prepareEngine() {
        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            engine?.stoppedHandler = { _ in }
            try engine?.start()
        } catch {
            supportsHaptics = false
        }
    }

    /// Starts a progressive haptic ramp from light to strong over `duration` seconds.
    /// Intensity ramps 0.2 -> 1.0, sharpness ramps 0.3 -> 0.8.
    func startRamp(duration: TimeInterval = 0.8) {
        guard supportsHaptics, let engine else {
            startFallbackRamp(duration: duration)
            return
        }

        do {
            try engine.start()

            let intensityStart = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2)
            let sharpnessStart = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensityStart, sharpnessStart],
                relativeTime: 0,
                duration: duration
            )

            let intensityRamp = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0, value: 0.2),
                    .init(relativeTime: duration * 0.5, value: 0.6),
                    .init(relativeTime: duration, value: 1.0)
                ],
                relativeTime: 0
            )

            let sharpnessRamp = CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    .init(relativeTime: 0, value: 0.3),
                    .init(relativeTime: duration, value: 0.8)
                ],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(
                events: [event],
                parameterCurves: [intensityRamp, sharpnessRamp]
            )

            player = try engine.makeAdvancedPlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            startFallbackRamp(duration: duration)
        }
    }

    func cancelRamp() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    /// Plays a satisfying completion burst haptic.
    func playCompletionBurst() {
        guard supportsHaptics, let engine else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        do {
            try engine.start()

            let sharpHit = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0
            )

            let warmHit = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.08
            )

            let pattern = try CHHapticPattern(events: [sharpHit, warmHit], parameters: [])
            let burstPlayer = try engine.makePlayer(with: pattern)
            try burstPlayer.start(atTime: CHHapticTimeImmediate)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - UIKit fallback for devices without CoreHaptics

    private var fallbackTimer: Timer?

    private func startFallbackRamp(duration: TimeInterval) {
        let steps = 6
        let interval = duration / Double(steps)
        var current = 0

        fallbackTimer?.invalidate()
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            current += 1
            let style: UIImpactFeedbackGenerator.FeedbackStyle
            switch current {
            case 1...2: style = .light
            case 3...4: style = .medium
            default: style = .heavy
            }
            UIImpactFeedbackGenerator(style: style).impactOccurred()

            if current >= steps {
                timer.invalidate()
                self?.fallbackTimer = nil
            }
        }
    }

    func stopFallback() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }
}
