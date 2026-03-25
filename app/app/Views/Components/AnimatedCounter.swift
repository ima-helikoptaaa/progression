import SwiftUI

struct AnimatedCounter: View {
    let value: Int
    var font: Font = .system(size: 24, weight: .bold, design: .rounded)
    var color: Color = Theme.Colors.textPrimary

    @State private var displayValue: Int = 0
    @State private var hasAppeared = false
    @State private var animationTimer: Timer?

    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(displayValue)))
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                animateCount()
            }
            .onChange(of: value) {
                animateCount()
            }
            .onDisappear {
                animationTimer?.invalidate()
                animationTimer = nil
            }
    }

    private func animateCount() {
        animationTimer?.invalidate()

        let steps = min(value, 30)
        guard steps > 0 else {
            displayValue = value
            return
        }

        let duration = 0.8
        let interval = duration / Double(steps)
        var currentStep = 0

        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            currentStep += 1
            withAnimation(.easeOut(duration: 0.05)) {
                if currentStep >= steps {
                    displayValue = value
                    timer.invalidate()
                    animationTimer = nil
                } else {
                    displayValue = Int(Double(value) * Double(currentStep) / Double(steps))
                }
            }
        }
    }
}

struct AnimatedCounterLarge: View {
    let value: Int
    var font: Font = .system(size: 48, weight: .bold, design: .rounded)
    var color: Color = Theme.Colors.textPrimary

    var body: some View {
        AnimatedCounter(value: value, font: font, color: color)
    }
}
