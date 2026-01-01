import SwiftUI

struct GradientBackground: View {
    let moodScore: Double

    var body: some View {
        Color.moodGradient(for: moodScore)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: Constants.Design.animationDuration), value: moodScore)
    }
}

struct AnimatedGradientBackground: View {
    let moodScore: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
            AnimatedGradientCanvas(
                moodScore: moodScore,
                phase: computePhase(from: timeline.date)
            )
        }
        .ignoresSafeArea()
    }

    private func computePhase(from date: Date) -> Double {
        date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10) / 10
    }
}

private struct AnimatedGradientCanvas: View {
    let moodScore: Double
    let phase: Double

    var body: some View {
        Canvas { context, size in
            let colors = Color.moodColors(for: moodScore)
            let gradient = Gradient(colors: colors)

            let startX = size.width * (0.3 + 0.2 * sin(phase * .pi * 2))
            let startY = size.height * (0.2 + 0.1 * cos(phase * .pi * 2))
            let endX = size.width * (0.7 + 0.2 * cos(phase * .pi * 2))
            let endY = size.height * (0.8 + 0.1 * sin(phase * .pi * 2))

            let startPoint = CGPoint(x: startX, y: startY)
            let endPoint = CGPoint(x: endX, y: endY)
            let rect = CGRect(origin: .zero, size: size)

            context.fill(
                Path(rect),
                with: .linearGradient(gradient, startPoint: startPoint, endPoint: endPoint)
            )
        }
    }
}

#Preview {
    VStack {
        GradientBackground(moodScore: -3.0)
        GradientBackground(moodScore: 0.0)
        GradientBackground(moodScore: 3.0)
    }
}
