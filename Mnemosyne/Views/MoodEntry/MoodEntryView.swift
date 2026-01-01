import SwiftUI

struct MoodEntryView: View {
    @StateObject private var viewModel = MoodEntryViewModel()
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        ZStack {
            // Animated gradient background
            GradientBackground(moodScore: viewModel.moodScore)

            VStack(spacing: 0) {
                switch viewModel.currentStep {
                case .mood:
                    moodInputView

                case .tags:
                    TagSelectionView(
                        selectedTags: $viewModel.selectedTags,
                        onContinue: viewModel.proceedFromTags,
                        onSkip: viewModel.skipTags,
                        onBack: viewModel.goBack
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                case .flow:
                    FlowSelectionView(
                        selectedFlow: $viewModel.menstrualFlow,
                        onContinue: viewModel.proceedToConfirmation,
                        onSkip: viewModel.skipFlow,
                        onBack: viewModel.goBack
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                case .confirmation:
                    MoodConfirmationView(
                        moodScore: viewModel.moodScore,
                        tags: Array(viewModel.selectedTags),
                        onDone: viewModel.reset
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
    }

    // MARK: - Mood Input View

    private var moodInputView: some View {
        VStack(spacing: Constants.Design.largeSpacing) {
            // Header met navigatie
            header

            Spacer()

            // Centrale animerende vorm
            MoodShape(moodScore: viewModel.moodScore)
                .frame(width: 220, height: 220)
                .padding(.bottom, Constants.Design.spacing)

            // Mood label
            MoodLabel(moodScore: viewModel.moodScore)

            Spacer()

            // Slider sectie
            VStack(spacing: Constants.Design.smallSpacing) {
                Text("Kies hoe je je op dit moment voelt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                MoodSlider(
                    value: $viewModel.moodScore,
                    range: Constants.Mood.minScore...Constants.Mood.maxScore
                )
                .padding(.horizontal, Constants.Design.largeSpacing)

                SliderLabels()
                    .padding(.horizontal, Constants.Design.largeSpacing)
            }
            .padding(.bottom, Constants.Design.largeSpacing)

            // Stats (alleen tonen als er entries zijn)
            if viewModel.todayEntryCount > 0 {
                statsBar
                    .padding(.bottom, Constants.Design.spacing)
            }
        }
        .padding()
        .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Vandaag")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            Button(action: viewModel.proceedToTags) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: Constants.Design.largeSpacing) {
            StatItem(
                value: "\(viewModel.todayEntryCount)",
                label: "vandaag"
            )

            StatItem(
                value: "\(viewModel.streakCount)",
                label: "dagen streak"
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MoodEntryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
