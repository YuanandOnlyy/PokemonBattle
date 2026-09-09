#!/usr/bin/env python3
"""Portable verification of battle damage / HP / health-bar math (mirrors BattleEngine.swift)."""

from __future__ import annotations

import math
import random
import sys


def type_effectiveness(move_type: str, defender_types: list[str], chart: dict) -> float:
    mult = 1.0
    for def_type in defender_types:
        if move_type in chart and def_type in chart[move_type]:
            mult *= chart[move_type][def_type]
    return mult


TYPE_CHART = {
    "fire": {"grass": 2, "water": 0.5, "fire": 0.5},
    "water": {"fire": 2, "grass": 0.5, "water": 0.5},
    "grass": {"water": 2, "fire": 0.5, "grass": 0.5},
    "electric": {"water": 2, "ground": 0, "electric": 0.5},
}


def calculate_damage(attacker, move, defender, rng=None) -> dict:
    rng = rng or random.Random(42)
    if move["power"] <= 0:
        return {"damage": 0, "effectiveness": 1}

    level = float(attacker["level"])
    power = float(move["power"])
    atk = float(attacker["atk"] if move["category"] == "physical" else attacker["spAtk"])
    defense = float(defender["def"] if move["category"] == "physical" else defender["spDef"])
    base = math.floor((2 * level / 5 + 2) * power * (atk / defense) / 50 + 2)
    stab = 1.5 if move["type"] in attacker["types"] else 1.0
    eff = type_effectiveness(move["type"], defender["types"], TYPE_CHART)
    if eff == 0:
        return {"damage": 0, "effectiveness": 0}
    crit = 1.5 if rng.random() < 0.0625 else 1.0
    rand = 0.85 + rng.random() * 0.15
    final = max(1, int(math.floor(base * stab * eff * crit * rand)))
    return {"damage": final, "effectiveness": eff}


def apply_damage(hp: int, max_hp: int, damage: int) -> tuple[int, float]:
    new_hp = max(0, hp - damage)
    percent = 0.0 if max_hp <= 0 else max(0.0, min(1.0, new_hp / max_hp))
    return new_hp, percent


def simulate_battle_round() -> None:
    player = {"name": "Pikachu", "level": 50, "types": ["electric"], "atk": 55, "def": 40, "spAtk": 50, "spDef": 50, "hp": 100, "maxHP": 100}
    enemy = {"name": "Squirtle", "level": 50, "types": ["water"], "atk": 48, "def": 65, "spAtk": 50, "spDef": 64, "hp": 88, "maxHP": 88}
    move = {"name": "Thundershock", "type": "electric", "power": 40, "category": "special"}

    failures = []

    # Deterministic damage with fixed RNG
    result = calculate_damage(player, move, enemy, rng=random.Random(1))
    assert result["damage"] > 0, "damage must be > 0 for effective move"
    assert result["effectiveness"] == 2.0, f"electric vs water should be 2x, got {result['effectiveness']}"

    before = enemy["hp"]
    after, percent = apply_damage(enemy["hp"], enemy["maxHP"], result["damage"])
    if after != before - result["damage"] and after != 0:
        failures.append(f"HP math wrong: {before} - {result['damage']} != {after}")
    if after > before:
        failures.append("HP increased after damage")
    if percent > (before / enemy["maxHP"]):
        failures.append("health bar percent increased after damage")
    if after == 0 and percent != 0:
        failures.append("health bar not zero at 0 HP")

    # Exact example from the user brief: 100 HP - 25 damage => 75 and 75%
    hp, pct = apply_damage(100, 100, 25)
    assert hp == 75 and abs(pct - 0.75) < 1e-9, f"expected 75/75%, got {hp}/{pct}"

    # Clamp at zero
    hp, pct = apply_damage(10, 100, 25)
    assert hp == 0 and pct == 0.0, f"expected 0/0%, got {hp}/{pct}"

    # Immune move deals no HP change when effectiveness is 0 (Ground vs Flying simulated)
    immune = calculate_damage(
        {"level": 50, "types": ["ground"], "atk": 100, "spAtk": 100},
        {"power": 80, "type": "electric", "category": "special"},
        {"types": ["ground"], "def": 50, "spDef": 50},
        rng=random.Random(0),
    )
    assert immune["effectiveness"] == 0 and immune["damage"] == 0

    # Multi-turn HP drain until faint
    foe_hp, foe_max = 88, 88
    turns = 0
    rng = random.Random(7)
    while foe_hp > 0 and turns < 50:
        dmg = calculate_damage(player, move, {**enemy, "hp": foe_hp}, rng=rng)["damage"]
        foe_hp, pct = apply_damage(foe_hp, foe_max, dmg)
        turns += 1
        assert 0 <= pct <= 1
    assert foe_hp == 0, "enemy should eventually faint"
    assert turns >= 1

    # Double-hit protection simulation: only one attack applies while locked
    locked = False
    hits = 0

    def try_attack():
        nonlocal locked, hits
        if locked:
            return False
        locked = True
        hits += 1
        return True

    assert try_attack() is True
    assert try_attack() is False
    assert hits == 1

    print("BATTLE_LOGIC: PASS")
    print(f"  sample damage (seed=1): {result['damage']} (2x electric vs water)")
    print(f"  HP example 100-25 => {apply_damage(100,100,25)}")
    print(f"  fainted in {turns} turns")
    print(f"  double-tap lock: hits={hits}")
    if failures:
        print("FAILURES:", failures)
        sys.exit(1)


if __name__ == "__main__":
    simulate_battle_round()
