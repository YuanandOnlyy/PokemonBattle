import Foundation
import SwiftUI

/// Mirrors `TeamBuilder.tsx`: pick exactly 3 Pokemon (search + type filter grid) before battling.
struct TeamBuilderView: View {
    var viewModel: GameViewModel

    private static let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    @State private var team: [Pokemon?] = [nil, nil, nil]
    @State private var errorMessage = ""
    @State private var search = ""
    @State private var typeFilter: PokemonType?

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }
    private var teamIDs: Set<Int> { Set(team.compactMap { $0?.id }) }
    private var teamCount: Int { team.compactMap { $0 }.count }

    private var filtered: [Pokemon] {
        GameData.allPokemon.filter { pokemon in
            let matchesSearch = search.isEmpty || pokemon.name.localizedCaseInsensitiveContains(search)
            let matchesType = typeFilter == nil || pokemon.types.contains(typeFilter ?? .normal)
            return matchesSearch && matchesType
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header.staggerAppear(0)
            teamSlots.staggerAppear(1)
            searchAndFilter.staggerAppear(2)
            pokemonGrid.staggerAppear(3)
        }
        .background(skin.medium)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.navigate(.title)
            } label: {
                Text("\u{25C0}").font(.pixel(12)).foregroundStyle(skin.lightest)
            }
            .buttonStyle(.plain)

            Text("TEAM BUILDER").pixelText(10, skin.lightest)
            Spacer()
            Text("\(teamCount)/3").pixelText(8, teamCount == 3 ? Color(hex: "#c0a000") : skin.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(skin.darkest)
        .overlay(Rectangle().fill(skin.dark).frame(height: 4), alignment: .bottom)
    }

    private var teamSlots: some View {
        VStack(spacing: 8) {
            Text("YOUR TEAM").pixelText(8, skin.light)

            HStack(spacing: 8) {
                ForEach(team.indices, id: \.self) { index in
                    teamSlot(index)
                }
            }

            if !errorMessage.isEmpty {
                Text("\u{26A0} \(errorMessage)").pixelText(8, Color(hex: "#c04000"))
            }

            Button {
                startBattle()
            } label: {
                Text(teamCount < 3 ? "CHOOSE \(3 - teamCount) MORE" : "\u{2694} START BATTLE!")
            }
            .buttonStyle(RetroButtonStyle(skin: skin, fontSize: 11, isDisabled: teamCount < 3))
            .disabled(teamCount < 3)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(skin.dark)
        .overlay(Rectangle().fill(skin.darkest).frame(height: 4), alignment: .bottom)
    }

    private func teamSlot(_ index: Int) -> some View {
        let pokemon = team[index]
        return VStack(spacing: 2) {
            if let pokemon {
                OfficialSpriteView(id: pokemon.id, width: 60, height: 60)
                Text(pokemon.name.uppercased()).pixelText(6, skin.darkest)
                HStack(spacing: 2) {
                    ForEach(pokemon.types, id: \.self) { TypeBadgeView(type: $0) }
                }
            } else {
                Rectangle()
                    .stroke(skin.medium, style: StrokeStyle(lineWidth: 3, dash: [4]))
                    .frame(width: 32, height: 32)
                    .overlay(Text("\(index + 1)").font(.pixel(14)).foregroundStyle(skin.medium))
                Text("EMPTY").pixelText(6, skin.medium)
            }
        }
        .frame(width: 96, height: 100)
        .background(pokemon != nil ? skin.lightest : Color(hex: "#1a3a1a"))
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
        .onTapGesture {
            if team[index] != nil {
                team[index] = nil
                errorMessage = ""
            }
        }
    }

    private var searchAndFilter: some View {
        VStack(alignment: .leading, spacing: 5) {
            TextField("", text: $search, prompt: Text("\u{1F50D} SEARCH POKEMON...").foregroundColor(skin.dark))
                .font(.pixel(8))
                .foregroundStyle(skin.darkest)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(skin.lightest)
                .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))

            TypeFilterBar(selected: typeFilter, skin: skin) { typeFilter = $0 }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(skin.dark)
        .overlay(Rectangle().fill(skin.darkest).frame(height: 3), alignment: .bottom)
    }

    private var pokemonGrid: some View {
        ScrollView {
            if filtered.isEmpty {
                Text("NO POKEMON FOUND")
                    .pixelText(9, skin.dark)
                    .padding(20)
            } else {
                LazyVGrid(columns: Self.columns, spacing: 6) {
                    ForEach(filtered) { pokemon in
                        pokemonCard(pokemon)
                    }
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pokemonCard(_ pokemon: Pokemon) -> some View {
        let inTeam = teamIDs.contains(pokemon.id)
        let teamFull = teamCount >= 3
        let disabled = inTeam || (!inTeam && teamFull)

        return VStack(spacing: 2) {
            if inTeam {
                Text("\u{2713}")
                    .font(.pixel(9))
                    .foregroundStyle(skin.darkest)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            OfficialSpriteView(id: pokemon.id, width: 54, height: 54)
            Text(pokemon.name.uppercased())
                .pixelText(6, inTeam ? skin.darkest : (disabled ? skin.medium : skin.darkest))
            Text("#\(String(format: "%03d", pokemon.id))").pixelText(6, skin.dark)
            HStack(spacing: 2) {
                ForEach(pokemon.types, id: \.self) { TypeBadgeView(type: $0) }
            }
            Text("HP:\(pokemon.baseHP) SPD:\(pokemon.spd)")
                .font(.pixel(5))
                .foregroundStyle(skin.dark)
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .padding(.bottom, 5)
        .frame(maxWidth: .infinity)
        .background(inTeam ? Color(hex: "#e8d870") : (disabled ? Color(hex: "#2a3a2a") : skin.lightest))
        .overlay(Rectangle().stroke(inTeam ? Color(hex: "#c0a000") : skin.darkest, lineWidth: 4))
        .opacity((!inTeam && teamFull) ? 0.45 : 1)
        .onTapGesture {
            guard !disabled else { return }
            addToTeam(pokemon)
        }
    }

    private func addToTeam(_ pokemon: Pokemon) {
        guard !teamIDs.contains(pokemon.id) else { return }
        guard let emptyIndex = team.firstIndex(where: { $0 == nil }) else { return }
        team[emptyIndex] = pokemon
        errorMessage = ""
    }

    private func startBattle() {
        let selected = team.compactMap { $0 }
        guard selected.count >= 3 else {
            errorMessage = "SELECT 3 POKEMON TO CONTINUE!"
            return
        }
        viewModel.startBattle(playerTeam: selected)
    }
}
