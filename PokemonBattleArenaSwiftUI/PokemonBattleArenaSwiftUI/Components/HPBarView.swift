import SwiftUI

/// Mirrors `HPBar` in ui.tsx / the inline `HPBar` in BattleScreen.tsx: a bordered track with a
/// fill that goes green > 50%, yellow 25-50%, red below that.
struct HPBarView: View {
    var current: Int
    var max: Int
    var compact: Bool = false
    var skin: SkinColors

    private var percent: Double {
        guard max > 0 else { return 0 }
        return Swift.max(0, Swift.min(1, Double(current) / Double(max)))
    }

    private var fillColor: Color {
        if percent > 0.5 { return skin.dark }
        if percent > 0.25 { return Color(hex: "#c0a000") }
        return Color(hex: "#c04000")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(skin.darkest)
                Rectangle()
                    .fill(fillColor)
                    .frame(width: geo.size.width * percent)
                    .animation(.easeInOut(duration: 0.5), value: percent)
            }
        }
        .frame(height: compact ? 6 : 8)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
    }
}

/// Mirrors `XPBar` in ui.tsx: a blue fill on a dark track.
struct XPBarView: View {
    var current: Int
    var max: Int
    var skin: SkinColors

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
                    .frame(width: geo.size.width * percent)
                    .animation(.easeInOut(duration: 0.5), value: percent)
            }
        }
        .frame(height: 6)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
    }
}
