import SwiftUI

/// Mirrors `HPBar` in ui.tsx / the inline `HPBar` in BattleScreen.tsx: a bordered track with a
/// fill that goes green > 50%, yellow 25-50%, red below that. The fill width is driven by the
/// live HP ratio and animates whenever `current` changes so damage is visually obvious.
struct HPBarView: View {
    var current: Int
    var max: Int
    var compact: Bool = false
    var skin: SkinColors

    @State private var displayedPercent: Double = 0

    private var percent: Double {
        guard max > 0 else { return 0 }
        return Swift.max(0, Swift.min(1, Double(current) / Double(max)))
    }

    private var fillColor: Color {
        if displayedPercent > 0.5 { return skin.dark }
        if displayedPercent > 0.25 { return Color(hex: "#c0a000") }
        return Color(hex: "#c04000")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(skin.darkest)
                Rectangle()
                    .fill(fillColor)
                    .frame(width: geo.size.width * displayedPercent)
                    .animation(.easeOut(duration: 0.6), value: displayedPercent)
            }
        }
        .frame(height: compact ? 10 : 14)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
        .onAppear { displayedPercent = percent }
        .onChange(of: current) { _, _ in
            // Defer into a fresh Task so the withAnimation transaction is not swallowed
            // inside the current @Observable render pass.
            Task { @MainActor in
                withAnimation(.easeOut(duration: 0.6)) { displayedPercent = percent }
            }
        }
        .accessibilityLabel("HP \(current) of \(max)")
    }
}

/// Mirrors `XPBar` in ui.tsx: a blue fill on a dark track.
struct XPBarView: View {
    var current: Int
    var max: Int
    var skin: SkinColors

    @State private var displayedPercent: Double = 0

    private var percent: Double {
        guard max > 0 else { return 0 }
        return Swift.max(0, Swift.min(1, Double(current) / Double(max)))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(skin.darkest)
                Rectangle()
                    .fill(Color(hex: "#4080ff"))
                    .frame(width: geo.size.width * displayedPercent)
                    .animation(.easeOut(duration: 0.6), value: displayedPercent)
            }
        }
        .frame(height: 8)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
        .onAppear { displayedPercent = percent }
        .onChange(of: current) { _, _ in
            Task { @MainActor in
                withAnimation(.easeOut(duration: 0.6)) { displayedPercent = percent }
            }
        }
    }
}
