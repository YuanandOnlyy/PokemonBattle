import SwiftUI

/// Mirrors the `TYPE_FILTERS` chip row used identically on TeamBuilder.tsx and Pokedex.tsx
/// (`ALL FIRE WATER GRASS ELECTRIC PSYCHIC DRAGON GHOST FIGHTING NORMAL`, wrapping to a second line).
struct TypeFilterBar: View {
    static let filters: [PokemonType?] = [
        nil, .fire, .water, .grass, .electric, .psychic, .dragon, .ghost, .fighting, .normal,
    ]

    var selected: PokemonType?
    var skin: SkinColors
    var onSelect: (PokemonType?) -> Void

    var body: some View {
        FlowLayout(spacing: 3, lineSpacing: 3) {
            ForEach(Array(Self.filters.enumerated()), id: \.offset) { _, type in
                let isSelected = selected == type
                Button {
                    onSelect(type)
                } label: {
                    Text(type?.rawValue ?? "ALL")
                        .font(.pixel(6))
                        .foregroundStyle(isSelected ? skin.lightest : skin.darkest)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(isSelected ? skin.darkest : skin.medium)
                        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
