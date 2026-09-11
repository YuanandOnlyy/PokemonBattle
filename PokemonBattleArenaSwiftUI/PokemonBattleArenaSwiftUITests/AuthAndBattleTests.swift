import Foundation
import Testing
@testable import PokemonBattleArenaSwiftUI

@Suite("AuthValidators")
struct AuthValidatorsTests {
    @Test("trainer name length")
    func trainerNameLength() {
        #expect(AuthValidators.isValidTrainerName("A"))
        #expect(AuthValidators.isValidTrainerName("ASH KETCHUM"))
        #expect(AuthValidators.isValidTrainerName(String(repeating: "X", count: 12)))
        #expect(!AuthValidators.isValidTrainerName(""))
        #expect(!AuthValidators.isValidTrainerName("   "))
        #expect(!AuthValidators.isValidTrainerName(String(repeating: "X", count: 13)))
    }

    @Test("email format")
    func emailFormat() {
        #expect(AuthValidators.isValidEmail("ash@pallet.town"))
        #expect(AuthValidators.isValidEmail("trainer+1@example.com"))
        #expect(!AuthValidators.isValidEmail(""))
        #expect(!AuthValidators.isValidEmail("not-an-email"))
        #expect(!AuthValidators.isValidEmail("@missing.local"))
    }

    @Test("password length and confirm match")
    func passwordRules() {
        #expect(!AuthValidators.isValidPassword("short"))
        #expect(AuthValidators.isValidPassword("longenough"))
        #expect(AuthValidators.passwordsMatch("longenough", "longenough"))
        #expect(!AuthValidators.passwordsMatch("longenough", "different1"))
    }

    @Test("primary button tracks validity in both modes")
    func primaryButtonValidity() {
        #expect(AuthFormLogic.primaryButtonEnabled(
            mode: .newTrainer, name: "ASH", email: "ash@a.com", password: "password1", confirm: "password1"
        ))
        #expect(!AuthFormLogic.primaryButtonEnabled(
            mode: .newTrainer, name: "", email: "ash@a.com", password: "password1", confirm: "password1"
        ))
        #expect(!AuthFormLogic.primaryButtonEnabled(
            mode: .newTrainer, name: "ASH", email: "ash@a.com", password: "password1", confirm: "nope"
        ))
        #expect(AuthFormLogic.primaryButtonEnabled(
            mode: .logIn, name: "", email: "ash@a.com", password: "password1", confirm: ""
        ))
        #expect(!AuthFormLogic.primaryButtonEnabled(
            mode: .logIn, name: "", email: "bad", password: "password1", confirm: ""
        ))
    }
}

@Suite("AuthFormLogic")
struct AuthFormLogicTests {
    @Test("mode toggle swaps fields and preserves email")
    func modeTogglePreservesEmail() {
        let email = "ash@pallet.town"
        var error: String? = "THAT EMAIL IS ALREADY REGISTERED!"
        let switched = AuthFormLogic.switchMode(from: .newTrainer, to: .logIn, email: email, clearError: &error)
        #expect(switched.mode == .logIn)
        #expect(switched.email == email)
        #expect(error == nil)
        #expect(AuthFormLogic.visibleFields(for: .newTrainer).contains("confirmPassword"))
        #expect(!AuthFormLogic.visibleFields(for: .logIn).contains("confirmPassword"))
        #expect(AuthFormLogic.visibleFields(for: .logIn).contains("email"))
    }
}

@Suite("AuthService")
@MainActor
struct AuthServiceTests {
    @Test("sign-up success inserts trainers row with matching auth user id")
    func signUpSuccess() async {
        let userId = UUID()
        let auth = MockAuthAPI()
        let trainers = MockTrainersAPI()
        auth.signUpHandler = { _, _ in userId }

        let service = AuthService(authAPI: auth, trainersAPI: trainers)
        await service.signUp(email: "ash@a.com", password: "password1", trainerName: "ASH", avatarKey: "default_trainer")

        guard case .signedIn(let profile) = service.state else {
            Issue.record("expected signedIn, got \(service.state)")
            return
        }
        #expect(profile.id == userId)
        #expect(profile.trainerName == "ASH")
        #expect(trainers.inserted.count == 1)
        #expect(trainers.inserted[0].id == userId)
        #expect(trainers.stored[userId]?.id == userId)
    }

    @Test("log-in success loads trainers row")
    func logInSuccess() async {
        let userId = UUID()
        let auth = MockAuthAPI()
        let trainers = MockTrainersAPI()
        let saved = TrainerProfile.fresh(id: userId, trainerName: "MISTY", avatarKey: "misty_band")
        trainers.stored[userId] = saved
        auth.signInHandler = { _, _ in userId }

        let service = AuthService(authAPI: auth, trainersAPI: trainers)
        await service.logIn(email: "misty@a.com", password: "password1")

        guard case .signedIn(let profile) = service.state else {
            Issue.record("expected signedIn, got \(service.state)")
            return
        }
        #expect(profile.trainerName == "MISTY")
    }

    @Test("wrong password maps to trainer-id error")
    func wrongPassword() async {
        let auth = MockAuthAPI()
        let trainers = MockTrainersAPI()
        auth.signInHandler = { _, _ in throw AuthStubError.wrongPassword }

        let service = AuthService(authAPI: auth, trainersAPI: trainers)
        await service.logIn(email: "ash@a.com", password: "wrongpass")

        guard case .error(let message) = service.state else {
            Issue.record("expected error, got \(service.state)")
            return
        }
        #expect(message == "TRAINER ID NOT RECOGNIZED. TRY AGAIN!")
    }

    @Test("duplicate email maps to already-registered error")
    func duplicateEmail() async {
        let auth = MockAuthAPI()
        let trainers = MockTrainersAPI()
        auth.signUpHandler = { _, _ in throw AuthStubError.duplicateEmail }

        let service = AuthService(authAPI: auth, trainersAPI: trainers)
        await service.signUp(email: "ash@a.com", password: "password1", trainerName: "ASH", avatarKey: "default_trainer")

        guard case .error(let message) = service.state else {
            Issue.record("expected error, got \(service.state)")
            return
        }
        #expect(message == "THAT EMAIL IS ALREADY REGISTERED!")
    }

    @Test("restore session with no session stays signed out")
    func restoreNoSession() async {
        let auth = MockAuthAPI()
        let trainers = MockTrainersAPI()
        auth.currentUserHandler = { throw AuthStubError.noSession }

        let service = AuthService(authAPI: auth, trainersAPI: trainers)
        await service.restoreSession()
        #expect(service.state == .signedOut)
        #expect(service.hasCheckedSession)
    }
}

@Suite("BattleDamageAndHP")
struct BattleDamageAndHPTests {
    private func samplePokemon(id: Int, name: String, types: [PokemonType], hp: Int, atk: Int, spAtk: Int, def: Int, spDef: Int) -> BattlePokemon {
        BattlePokemon(
            id: id, name: name, types: types, baseHP: hp,
            atk: atk, def: def, spAtk: spAtk, spDef: spDef, spd: 50,
            moves: [Move(name: "Tackle", type: .normal, power: 40, accuracy: 100, maxPP: 35)],
            level: 50, xp: 0, xpToNext: 100, ability: nil,
            evolvesInto: nil, evolutionOf: nil, evolutionLevel: nil, rarity: nil,
            currentHP: hp, maxHP: hp, status: nil,
            sleepTurns: 0, statusTurnsLeft: 0, isFainted: false, tempAtkBoost: 1, tempDefBoost: 1
        )
    }

    @Test("pinned damage yields previousHP - expectedDamage")
    func deterministicDamageHP() {
        let attacker = samplePokemon(id: 25, name: "Pikachu", types: [.electric], hp: 100, atk: 55, spAtk: 50, def: 40, spDef: 50)
        var defender = samplePokemon(id: 7, name: "Squirtle", types: [.water], hp: 88, atk: 48, spAtk: 50, def: 65, spDef: 64)
        let move = Move(name: "Thunder Shock", type: .electric, power: 40, accuracy: 100, maxPP: 30, category: .special)

        let result = BattleEngine.calculateDamage(
            attacker: attacker, move: move, defender: defender,
            critRoll: 0.99, varianceRoll: 0.0
        )
        #expect(result.damage > 0)
        #expect(result.effectiveness == 2.0)

        let previous = defender.currentHP
        let newHP = BattleEngine.applyDamage(to: &defender, damage: result.damage)
        #expect(newHP == max(0, previous - result.damage))
    }

    @Test("battle state HP property updates for the view binding source")
    func battleStateHPMutationReachesSourceOfTruth() {
        let enemySnapshot = samplePokemon(id: 7, name: "Squirtle", types: [.water], hp: 100, atk: 48, spAtk: 50, def: 65, spDef: 64)
        let player = samplePokemon(id: 25, name: "Pikachu", types: [.electric], hp: 100, atk: 55, spAtk: 50, def: 40, spDef: 50)
        var state = BattleState(
            playerTeam: [player], enemyTeam: [enemySnapshot],
            activePlayerIndex: 0, activeEnemyIndex: 0, phase: .menu,
            currentMessage: "", displayedMessage: "",
            turn: 1, startTime: Date(),
            totalDamageDealt: 0, totalCritHits: 0, totalSuperEffective: 0, itemsUsed: 0,
            damageByPokemon: ["Pikachu": 0],
            isPlayerShaking: false, isEnemyShaking: false,
            isPlayerFlashing: false, isEnemyFlashing: false, isScreenShaking: false,
            isPlayerLunging: false, isEnemyLunging: false,
            floatingDamage: nil, xpGained: [], levelUps: []
        )

        let previous = state.enemyTeam[0].currentHP
        let damage = 25
        _ = BattleEngine.applyDamage(to: &state.enemyTeam[0], damage: damage)

        // This is the property HPBarView / numeric label read.
        #expect(state.enemyTeam[0].currentHP == previous - damage)
        #expect(state.enemyTeam[0].currentHP != previous)

        // Equatable must see HP changes (regression for the id-only == bug).
        #expect(state.enemyTeam[0] != enemySnapshot)

        // Player path too.
        _ = BattleEngine.applyDamage(to: &state.playerTeam[0], damage: 10)
        #expect(state.playerTeam[0].currentHP == 90)
    }
}
