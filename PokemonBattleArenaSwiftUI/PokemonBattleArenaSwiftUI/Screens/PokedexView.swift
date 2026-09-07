import Foundation
import SwiftUI

/// Mirrors `Pokedex.tsx`: a searchable/filterable list that drills into a per-Pokemon detail view.
struct PokedexView: View {
    var viewModel: GameViewModel

    @State private var search = ""
    @State private var typeFilter: PokemonType?
    @State private var selected: Pokemon?

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }

    private var filtered: [Pokemon] {
        GameData.allPokemon.filter { pokemon in
            let matchesSearch = search.isEmpty
                || pokemon.name.localizedCaseInsensitiveContains(search)
                || String(pokemon.id).contains(search)
            let matchesType = typeFilter == nil || pokemon.types.contains(typeFilter ?? .normal)
            return matchesSearch && matchesType
        }
    }

    var body: some View {
        Group {
            if let selected {
                PokemonDetailView(pokemon: selected, skin: skin) { self.selected = nil }
            } else {
                listView
            }
        }
    }

    private var listView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    viewModel.navigate(.title)
                } label: {
                    Text("\u{25C0}").font(.pixel(12)).foregroundStyle(skin.lightest)
                }
                .buttonStyle(.plain)
                Text("POK\u{00C9}DEX").pixelText(10, skin.lightest)
                Spacer()
                Text("\(filtered.count)/\(GameData.allPokemon.count)").pixelText(8, skin.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(skin.darkest)
            .overlay(Rectangle().fill(skin.dark).frame(height: 4), alignment: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                TextField("", text: $search, prompt: Text("\u{1F50D} SEARCH BY NAME OR NUMBER...").foregroundColor(skin.dark))
                    .font(.pixel(8))
                    .foregroundStyle(skin.darkest)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(skin.lightest)
                    .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))

                TypeFilterBar(selected: typeFilter, skin: skin) { typeFilter = $0 }
            }
            .padding(8)
            .background(skin.dark)
            .overlay(Rectangle().fill(skin.darkest).frame(height: 3), alignment: .bottom)

            ScrollView {
                if filtered.isEmpty {
                    Text("NO POKEMON FOUND").pixelText(9, skin.dark).padding(20)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { pokemon in
                            Button {
                                selected = pokemon
                            } label: {
                                pokedexRow(pokemon)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(skin.medium)
    }

    private func pokedexRow(_ pokemon: Pokemon) -> some View {
        HStack(spacing: 10) {
            OfficialSpriteView(id: pokemon.id, width: 52, height: 52)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(pokemon.name.uppercased()).pixelText(9, skin.darkest)
                    Spacer()
                    Text("#\(String(format: "%03d", pokemon.id))").pixelText(8, skin.dark)
                }
                HStack(spacing: 3) {
                    ForEach(pokemon.types, id: \.self) { TypeBadgeView(type: $0) }
                }
                Text("HP:\(pokemon.baseHP) ATK:\(pokemon.atk) DEF:\(pokemon.def) SPD:\(pokemon.spd)")
                    .font(.pixel(6))
                    .foregroundStyle(skin.dark)
            }
            Text("\u{25B6}").font(.pixel(12)).foregroundStyle(skin.dark)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(skin.lightest)
        .overlay(Rectangle().fill(skin.medium).frame(height: 3), alignment: .bottom)
    }
}

/// Mirrors `PokemonDetail` in Pokedex.tsx.
private struct PokemonDetailView: View {
    var pokemon: Pokemon
    var skin: SkinColors
    var onBack: () -> Void

    private enum Tab: String, CaseIterable, Hashable {
        case stats, moves, info
    }

    @State private var activeTab: Tab = .stats

    private var extra: PokedexEntry? { PokedexData.entry(for: pokemon.id) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: onBack) {
                    Text("\u{25C0}").font(.pixel(12)).foregroundStyle(skin.lightest)
                }
                .buttonStyle(.plain)
                Text("#\(String(format: "%03d", pokemon.id)) \(pokemon.name.uppercased())")
                    .pixelText(9, skin.lightest)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(skin.darkest)
            .overlay(Rectangle().fill(skin.dark).frame(height: 4), alignment: .bottom)

            VStack(spacing: 6) {
                OfficialSpriteView(id: pokemon.id, width: 130, height: 130)
                HStack(spacing: 6) {
                    ForEach(pokemon.types, id: \.self) { TypeBadgeView(type: $0) }
                }
                if let extra {
                    Text("ABILITY: \(extra.ability.uppercased())").pixelText(7, skin.medium)
                }
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [skin.darkest, skin.dark], startPoint: .top, endPoint: .bottom))
            .overlay(Rectangle().fill(skin.darkest).frame(height: 4), alignment: .bottom)

            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        Text(tab.rawValue.uppercased())
                            .font(.pixel(8))
                            .foregroundStyle(activeTab == tab ? skin.darkest : skin.light)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(activeTab == tab ? skin.lightest : skin.dark)
                            .overlay(Rectangle().fill(skin.darkest).frame(width: 2), alignment: .trailing)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(skin.dark)
            .overlay(Rectangle().fill(skin.darkest).frame(height: 3), alignment: .bottom)

            ScrollView {
                switch activeTab {
                case .stats: statsTab
                case .moves: movesTab
                case .info: infoTab
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(skin.medium)
    }

    private var statsTab: some View {
        VStack(spacing: 10) {
            VStack(spacing: 7) {
                Text("BASE STATS")
                    .pixelText(9, skin.darkest)
                    .padding(.bottom, 6)
                    .overlay(Rectangle().fill(skin.medium).frame(height: 2), alignment: .bottom)

                statBar("HP", pokemon.baseHP, max: 200, color: Color(hex: "#c04000"))
                statBar("ATK", pokemon.atk, max: 160, color: Color(hex: "#c06000"))
                statBar("DEF", pokemon.def, max: 160, color: skin.dark)
                statBar("SP.ATK", pokemon.spAtk, max: 160, color: Color(hex: "#6000c0"))
                statBar("SP.DEF", pokemon.spDef, max: 160, color: Color(hex: "#004080"))
                statBar("SPEED", pokemon.spd, max: 160, color: Color(hex: "#c0a000"))
            }
            .padding(10)
            .background(skin.lightest)
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))

            HStack {
                Text("TOTAL BST").pixelText(8, skin.medium)
                Spacer()
                Text("\(pokemon.baseHP + pokemon.atk + pokemon.def + pokemon.spAtk + pokemon.spDef + pokemon.spd)")
                    .pixelText(8, Color(hex: "#c0a000"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(skin.darkest)
            .overlay(Rectangle().stroke(skin.dark, lineWidth: 3))
        }
    }

    private func statBar(_ label: String, _ value: Int, max maxValue: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(label).pixelText(7, skin.dark)
                Spacer()
                Text("\(value)").pixelText(8, skin.darkest)
            }
            GeometryReader { geo in
                let pct = min(1, Double(value) / Double(maxValue))
                ZStack(alignment: .leading) {
                    Rectangle().fill(skin.medium)
                    Rectangle().fill(color).frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 8)
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
        }
    }

    private var movesTab: some View {
        VStack(spacing: 6) {
            ForEach(pokemon.moves) { move in
                VStack(spacing: 4) {
                    HStack {
                        Text(move.name.uppercased()).pixelText(9, skin.darkest)
                        Spacer()
                        TypeBadgeView(type: move.type)
                    }
                    HStack(spacing: 10) {
                        Text("PWR: \(move.power > 0 ? "\(move.power)" : "--")")
                        Text("ACC: \(move.accuracy)%")
                        Text("PP: \(move.maxPP)")
                        Spacer()
                        Text(move.category.rawValue.uppercased()).foregroundStyle(skin.darkest)
                    }
                    .font(.pixel(7))
                    .foregroundStyle(skin.dark)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(skin.lightest)
                .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
            }
        }
    }

    @ViewBuilder
    private var infoTab: some View {
        if let extra {
            VStack(spacing: 10) {
                infoBox(title: "POK\u{00C9}DEX ENTRY", titleColor: skin.darkest) {
                    Text(extra.description).font(.pixel(7)).foregroundStyle(skin.dark).lineSpacing(8)
                }
                infoBox(title: "INFO", titleColor: skin.darkest) {
                    infoRow("HEIGHT", extra.height)
                    infoRow("WEIGHT", extra.weight)
                    infoRow("ABILITY", extra.ability.uppercased())
                    infoRow("LEVEL", "\(pokemon.level)")
                }
                infoBox(title: "\u{26A0} WEAK TO", titleColor: Color(hex: "#c04000")) {
                    FlowLayout(spacing: 4, lineSpacing: 4) {
                        ForEach(extra.weaknesses, id: \.self) { TypeBadgeView(type: $0) }
                    }
                }
                infoBox(title: "\u{2713} RESISTS", titleColor: skin.dark) {
                    FlowLayout(spacing: 4, lineSpacing: 4) {
                        ForEach(extra.resistances, id: \.self) { TypeBadgeView(type: $0) }
                    }
                }
            }
        } else {
            Text("DATA NOT FOUND").pixelText(9, skin.dark).padding(20)
        }
    }

    private func infoBox(title: String, titleColor: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .pixelText(9, titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(skin.medium).frame(height: 2), alignment: .bottom)
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(skin.lightest)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).pixelText(7, skin.dark)
            Spacer()
            Text(value).pixelText(7, skin.darkest)
        }
    }
}
