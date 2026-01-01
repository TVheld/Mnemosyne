import SwiftUI

struct TagPill: View {
    let tag: String
    let isSelected: Bool
    let isPositive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel(tag)
        .accessibilityValue(isSelected ? "geselecteerd" : "niet geselecteerd")
        .accessibilityHint(isSelected ? "Dubbeltik om te deselecteren" : "Dubbeltik om te selecteren")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var backgroundColor: Color {
        if isSelected {
            return isPositive ? .green.opacity(0.8) : .orange.opacity(0.8)
        } else {
            return .white.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else {
            return .primary
        }
    }

    private var borderColor: Color {
        isPositive ? .green.opacity(0.3) : .orange.opacity(0.3)
    }
}

struct TagSection: View {
    let title: String
    let tags: [String]
    let selectedTags: Set<String>
    let isPositive: Bool
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagPill(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        isPositive: isPositive,
                        action: { onToggle(tag) }
                    )
                }
            }
        }
    }
}

// Custom Flow Layout voor tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                self.size.width = max(self.size.width, currentX)
            }

            self.size.height = currentY + lineHeight
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TagPill(tag: "Hoofdpijn", isSelected: false, isPositive: false, action: {})
        TagPill(tag: "Hoofdpijn", isSelected: true, isPositive: false, action: {})
        TagPill(tag: "Energiek", isSelected: false, isPositive: true, action: {})
        TagPill(tag: "Energiek", isSelected: true, isPositive: true, action: {})
    }
    .padding()
}
