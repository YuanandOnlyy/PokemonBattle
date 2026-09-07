import SwiftUI

/// The four selectable device re-skins. Mirrors `ConsoleSkin` in types.ts.
enum ConsoleSkin: String, Codable, Hashable, CaseIterable {
    case dmg
    case pocket
    case crystal
    case advance
}

/// The full palette for one console skin. Mirrors `SkinColors` / `SKINS` in useSkin.ts.
/// All hex values are copied verbatim from the original app so colors match exactly.
struct SkinColors: Hashable {
    var name: String
    var darkest: Color
    var dark: Color
    var medium: Color
    var light: Color
    var lightest: Color
    var accent: Color
    var danger: Color
    var panelBg: Color
    var screenBg: Color

    static func == (lhs: SkinColors, rhs: SkinColors) -> Bool { lhs.name == rhs.name }
    func hash(into hasher: inout Hasher) { hasher.combine(name) }

    static let dmg = SkinColors(
        name: "DMG Classic",
        darkest: Color(hex: "#0f380f"), dark: Color(hex: "#306230"),
        medium: Color(hex: "#8bac0f"), light: Color(hex: "#9bbc0f"),
        lightest: Color(hex: "#e0f8d0"), accent: Color(hex: "#c0a000"),
        danger: Color(hex: "#c04000"), panelBg: Color(hex: "#e0f8d0"), screenBg: Color(hex: "#9bbc0f")
    )

    static let all: [ConsoleSkin: SkinColors] = [
        .dmg: .dmg,
        .pocket: SkinColors(
            name: "Pocket Gray",
            darkest: Color(hex: "#101010"), dark: Color(hex: "#3C3C3C"),
            medium: Color(hex: "#8C8C8C"), light: Color(hex: "#B0B0B0"),
            lightest: Color(hex: "#D6D6D6"), accent: Color(hex: "#ffffff"),
            danger: Color(hex: "#cc3333"), panelBg: Color(hex: "#D6D6D6"), screenBg: Color(hex: "#B0B0B0")
        ),
        .crystal: SkinColors(
            name: "Color Crystal",
            darkest: Color(hex: "#0B1E3A"), dark: Color(hex: "#1F6F6F"),
            medium: Color(hex: "#2A9D8F"), light: Color(hex: "#52B69A"),
            lightest: Color(hex: "#D4F1F4"), accent: Color(hex: "#F0C419"),
            danger: Color(hex: "#e63946"), panelBg: Color(hex: "#D4F1F4"), screenBg: Color(hex: "#52B69A")
        ),
        .advance: SkinColors(
            name: "Advance SP",
            darkest: Color(hex: "#1A1A3C"), dark: Color(hex: "#4B3B8C"),
            medium: Color(hex: "#7B6FC0"), light: Color(hex: "#9D8FE0"),
            lightest: Color(hex: "#E8E4FF"), accent: Color(hex: "#39D3D3"),
            danger: Color(hex: "#FF6B6B"), panelBg: Color(hex: "#E8E4FF"), screenBg: Color(hex: "#9D8FE0")
        ),
    ]
}

extension ConsoleSkin {
    /// Resolves this skin's palette. Falls back to `.dmg` colors if somehow missing (never happens
    /// in practice since `SkinColors.all` has an entry for every case, but keeps this non-optional).
    var colors: SkinColors {
        SkinColors.all[self] ?? .dmg
    }
}
