import SwiftUI

struct TagSelectionView: View {
    @Binding var selectedTags: Set<String>
    let onContinue: () -> Void
    let onSkip: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Design.largeSpacing) {
                    // Instructie
                    Text("Voeg context toe aan je stemming")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    // Negatieve/neutrale tags
                    TagSection(
                        title: "Hoe voel je je fysiek/mentaal?",
                        tags: Constants.Tags.negative,
                        selectedTags: selectedTags,
                        isPositive: false,
                        onToggle: toggleTag
                    )
                    .padding(.horizontal)

                    // Positieve tags
                    TagSection(
                        title: "Positieve momenten",
                        tags: Constants.Tags.positive,
                        selectedTags: selectedTags,
                        isPositive: true,
                        onToggle: toggleTag
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.top, Constants.Design.spacing)
            }

            // Bottom buttons
            bottomButtons
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("Context")
                .font(.headline)

            Spacer()

            // Placeholder voor symmetrie
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.vertical, Constants.Design.smallSpacing)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Doorgaan knop
            Button(action: onContinue) {
                Text(selectedTags.isEmpty ? "Overslaan" : "Doorgaan (\(selectedTags.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selectedTags.isEmpty ? Color.secondary : Color.pink)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func toggleTag(_ tag: String) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTags: Set<String> = ["Hoofdpijn", "Energiek"]

        var body: some View {
            TagSelectionView(
                selectedTags: $selectedTags,
                onContinue: {},
                onSkip: {},
                onBack: {}
            )
        }
    }

    return PreviewWrapper()
}
