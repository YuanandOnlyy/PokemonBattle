import SwiftUI

/// Mirrors `BattleHistory.tsx`: filterable, expandable log of past battle results.
struct BattleHistoryView: View {
    var viewModel: GameViewModel

    private enum Filter: String, CaseIterable, Hashable {
        case all = "ALL"
        case victories = "VICTORIES"
        case defeats = "DEFEATS"
    }

    @State private var filter: Filter = .all

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }
    private var history: [BattleRecord] { viewModel.trainerData.battleHistory }

    private var filtered: [BattleRecord] {
        switch filter {
        case .all: return history
        case .victories: return history.filter { $0.result == .victory }
        case .defeats: return history.filter { $0.result == .defeat }
        }
    }

    private var victories: Int { history.filter { $0.result == .victory }.count }
    private var defeats: Int { history.filter { $0.result == .defeat }.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            summaryBar
            filterTabs
            ScrollView {
                if filtered.isEmpty {
                    Text("NO BATTLES YET\nGO BATTLE!")
                        .pixelText(10, skin.dark)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(40)
                        .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { record in
                            BattleRecordRow(record: record, skin: skin)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            Text("BATTLE HISTORY").pixelText(9, skin.lightest)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(skin.darkest)
        .overlay(Rectangle().fill(skin.dark).frame(height: 4), alignment: .bottom)
    }

    private var summaryBar: some View {
        HStack {
            summaryStat("TOTAL", "\(history.count)", skin.light, skin.lightest)
            Spacer()
            summaryStat("WINS", "\(victories)", skin.accent, skin.accent)
            Spacer()
            summaryStat("LOSSES", "\(defeats)", skin.danger, skin.danger)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(skin.dark)
        .overlay(Rectangle().fill(skin.darkest).frame(height: 3), alignment: .bottom)
    }

    private func summaryStat(_ label: String, _ value: String, _ labelColor: Color, _ valueColor: Color) -> some View {
        VStack(spacing: 2) {
            Text(label).pixelText(7, labelColor)
            Text(value).pixelText(10, valueColor)
        }
    }

    private var filterTabs: some View {
        HStack(spacing: 4) {
            ForEach(Filter.allCases, id: \.self) { f in
                Button(f.rawValue) { filter = f }
                    .font(.pixel(7))
                    .foregroundStyle(skin.darkest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(filter == f ? skin.lightest : skin.medium)
                    .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(skin.dark)
        .overlay(Rectangle().fill(skin.darkest).frame(height: 3), alignment: .bottom)
    }
}

private struct BattleRecordRow: View {
    var record: BattleRecord
    var skin: SkinColors
    @State private var expanded = false

    private var isVictory: Bool { record.result == .victory }
    private var enemyID: Int { PokemonNameLookup.id(for: record.enemyPokemon) }
    private var playerLeadID: Int { record.playerTeam.first.map(PokemonNameLookup.id(for:)) ?? 25 }

    private var durationString: String {
        record.duration > 60 ? "\(record.duration / 60)m \(record.duration % 60)s" : "\(record.duration)s"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(isVictory ? "\u{2605}" : "\u{2717}")
                    .font(.system(size: 16))
                    .frame(width: 36, height: 36)
                    .background(isVictory ? skin.dark : Color(hex: "#6a0000"))
                    .overlay(Rectangle().stroke(isVictory ? skin.accent : skin.danger, lineWidth: 3))

                HStack(spacing: 2) {
                    OfficialSpriteView(id: playerLeadID, width: 36, height: 36)
                    Text("VS").pixelText(9, isVictory ? skin.dark : Color(hex: "#8b6060"))
                    OfficialSpriteView(id: enemyID, width: 36, height: 36)
                        .opacity(isVictory ? 0.6 : 1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(isVictory ? "\u{2605} WIN" : "\u{2717} LOSS")
                            .pixelText(9, isVictory ? skin.darkest : skin.danger)
                        Spacer()
                        Text("+\(record.xpGained) XP")
                            .font(.pixel(7))
                            .foregroundStyle(isVictory ? skin.dark : Color(hex: "#8b6060"))
                    }
                    Text("VS \(record.enemyPokemon.uppercased())")
                        .font(.pixel(7))
                        .foregroundStyle(isVictory ? skin.dark : Color(hex: "#8b6060"))
                    Text(record.date)
                        .font(.pixel(6))
                        .foregroundStyle(isVictory ? skin.medium : Color(hex: "#6a4a4a"))
                }

                Text("\u{25B6}")
                    .font(.pixel(9))
                    .foregroundStyle(isVictory ? skin.dark : Color(hex: "#8b6060"))
                    .rotationEffect(.degrees(expanded ? 90 : 0))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            if expanded {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TEAM: \(record.playerTeam.joined(separator: " \u{00B7} ").uppercased())")
                    Text("DURATION: \(durationString)")
                    Text("DAMAGE: \(record.damageDealt) | CRITS: \(record.critHits)")
                }
                .font(.pixel(7))
                .foregroundStyle(isVictory ? skin.dark : Color(hex: "#8b6060"))
                .lineSpacing(6)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isVictory ? skin.screenBg.opacity(0.5) : Color(hex: "#2a0a0a"))
                .overlay(Rectangle().fill(isVictory ? skin.medium : Color(hex: "#6a0000")).frame(height: 2), alignment: .top)
            }
        }
        .background(isVictory ? skin.panelBg : Color(hex: "#3a1a1a"))
        .overlay(Rectangle().fill(skin.medium).frame(height: 3), alignment: .bottom)
        .onTapGesture { expanded.toggle() }
    }
}
