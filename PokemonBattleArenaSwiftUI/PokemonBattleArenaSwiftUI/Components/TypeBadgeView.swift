import SwiftUI

/// Mirrors `TypeBadge` in ui.tsx: a small pill showing a move/Pokemon's type abbreviation.
struct TypeBadgeView: View {
    var type: PokemonType

    var body: some View {
        let colors = type.badgeColors
        Text(type.abbreviation)
            .font(.pixel(7))
            .foregroundStyle(colors.foreground)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(colors.background)
            .overlay(Rectangle().stroke(.black.opacity(0.3), lineWidth: 2))
    }
}

/// Mirrors `StatusBadge` in ui.tsx: a small blinking pill showing the current status condition.
struct StatusBadgeView: View {
    var status: StatusEffect
    @State private var visible = true

    private static let colors: [StatusEffect: (Color, Color)] = [
        .paralysis: (Color(hex: "#c0a000"), Color(hex: "#0f380f")),
        .burn: (Color(hex: "#c04000"), Color(hex: "#e0f8d0")),
        .poison: (Color(hex: "#800080"), Color(hex: "#e0f8d0")),
        .sleep: (Color(hex: "#306230"), Color(hex: "#e0f8d0")),
        .freeze: (Color(hex: "#00a0c0"), Color(hex: "#0f380f")),
    ]

    var body: some View {
        let pair = Self.colors[status] ?? (Color(hex: "#a0a0a0"), Color(hex: "#0f380f"))
        Text(status.abbreviation)
            .font(.pixel(7))
            .foregroundStyle(pair.1)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(pair.0)
            .overlay(Rectangle().stroke(.black.opacity(0.3), lineWidth: 2))
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}
