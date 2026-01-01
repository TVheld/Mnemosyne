import SwiftUI

struct MoodConfirmationView: View {
    let moodScore: Double
    let tags: [String]
    let onDone: () -> Void

    @State private var showCheckmark = false
    @State private var checkmarkScale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: Constants.Design.largeSpacing) {
            Spacer()

            // Checkmark animatie
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(checkmarkScale)
                    .opacity(showCheckmark ? 1 : 0)
            }

            // Bevestigingstekst
            VStack(spacing: 8) {
                Text("Vastgelegd")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(moodLabel)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))

                if !tags.isEmpty {
                    tagsDisplay
                }
            }

            Spacer()

            // Nieuwe entry knop
            Button(action: onDone) {
                Text("Nieuwe entry")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
            }
            .padding(.horizontal)
            .padding(.bottom, Constants.Design.largeSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moodGradient(for: moodScore))
        .onAppear {
            animateCheckmark()
        }
    }

    // MARK: - Computed Properties

    private var moodLabel: String {
        switch moodScore {
        case -5.0 ..< -3.0:
            return "Zeer onaangenaam"
        case -3.0 ..< -1.0:
            return "Onaangenaam"
        case -1.0 ..< 1.0:
            return "Neutraal"
        case 1.0 ..< 3.0:
            return "Aangenaam"
        case 3.0 ... 5.0:
            return "Zeer aangenaam"
        default:
            return "Neutraal"
        }
    }

    // MARK: - Tags Display

    private var tagsDisplay: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Animation

    private func animateCheckmark() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Checkmark animatie
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCheckmark = true
            checkmarkScale = 1.0
        }

        // Kleine bounce na
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                checkmarkScale = 1.1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                checkmarkScale = 1.0
            }
        }
    }
}

#Preview {
    MoodConfirmationView(
        moodScore: 3.5,
        tags: ["Energiek", "Productieve dag", "Goed geslapen"],
        onDone: {}
    )
}
