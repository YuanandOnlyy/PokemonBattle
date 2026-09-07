import SwiftUI

/// Builds PokeAPI sprite URLs. Mirrors the `src` logic in `PokemonSprite`/`OfficialSprite` in ui.tsx.
/// Per the chosen approach, sprites are streamed live from the same GitHub-hosted source the
/// original web app used rather than bundled into Assets.xcassets.
enum PokemonSpriteURL {
    private static let base = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon"

    static func gameBoy(id: Int, back: Bool) -> URL? {
        URL(string: back ? "\(base)/back/\(id).png" : "\(base)/\(id).png")
    }

    static func officialArtwork(id: Int) -> URL? {
        URL(string: "\(base)/other/official-artwork/\(id).png")
    }
}

/// Mirrors `PokemonSprite` in ui.tsx: the small pixel-art battle sprite, front or back facing.
struct PokemonSpriteView: View {
    var id: Int
    var back: Bool = false
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        AsyncImage(url: PokemonSpriteURL.gameBoy(id: id, back: back)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().interpolation(.none).aspectRatio(contentMode: .fit)
            case .failure:
                Color.clear
            case .empty:
                ProgressView()
            @unknown default:
                Color.clear
            }
        }
        .frame(width: width, height: height)
    }
}

/// Mirrors `OfficialSprite` in ui.tsx: the higher-resolution artwork used on menus/summary screens.
struct OfficialSpriteView: View {
    var id: Int
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        AsyncImage(url: PokemonSpriteURL.officialArtwork(id: id)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().interpolation(.none).aspectRatio(contentMode: .fit)
            case .failure:
                Color.clear
            case .empty:
                ProgressView()
            @unknown default:
                Color.clear
            }
        }
        .frame(width: width, height: height)
    }
}
