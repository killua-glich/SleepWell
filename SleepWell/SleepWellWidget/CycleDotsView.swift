import SwiftUI

/// Row of cycle dots. `filled` dots are indigo+glow; remaining are dimmed.
struct CycleDotsView: View {
    let filled: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < filled ? Color.accent : Color.accent.opacity(0.25))
                    .frame(width: 7, height: 7)
                    .shadow(color: index < filled ? Color.accent.opacity(0.8) : .clear, radius: 4)
            }
        }
    }
}
