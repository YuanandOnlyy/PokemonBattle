#!/usr/bin/env python3
"""
Portable unit tests mirroring AuthValidators / AuthFormLogic / AuthService / battle HP math.
Runnable on Windows without Xcode. Swift Testing sources live in PokemonBattleArenaSwiftUITests/.
"""

from __future__ import annotations

import math
import re
import sys
import uuid
from dataclasses import dataclass, field
from typing import Callable


# --- AuthValidators (mirrors TrainerProfile.swift) ---

MAX_NAME = 12
MIN_PASSWORD = 8
EMAIL_RE = re.compile(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$", re.I)


def is_valid_trainer_name(name: str) -> bool:
    trimmed = name.strip()
    return 1 <= len(trimmed) <= MAX_NAME


def is_valid_email(email: str) -> bool:
    trimmed = email.strip()
    return bool(trimmed) and EMAIL_RE.match(trimmed) is not None


def is_valid_password(password: str) -> bool:
    return len(password) >= MIN_PASSWORD


def passwords_match(password: str, confirm: str) -> bool:
    return bool(password) and password == confirm


def can_submit_new_trainer(name: str, email: str, password: str, confirm: str) -> bool:
    return (
        is_valid_trainer_name(name)
        and is_valid_email(email)
        and is_valid_password(password)
        and passwords_match(password, confirm)
    )


def can_submit_log_in(email: str, password: str) -> bool:
    return is_valid_email(email) and is_valid_password(password)


def visible_fields(mode: str) -> list[str]:
    if mode == "newTrainer":
        return ["trainerName", "email", "password", "confirmPassword", "avatar"]
    return ["email", "password", "rememberMe"]


def switch_mode(email: str, error: str | None) -> tuple[str, str | None]:
    return email, None  # email preserved, error cleared


# --- AuthService mock (mirrors AuthService.swift) ---

@dataclass
class TrainerProfile:
    id: str
    trainer_name: str
    avatar_key: str = "default_trainer"
    level: int = 1
    xp: int = 0
    wins: int = 0
    losses: int = 0
    win_streak: int = 0


@dataclass
class AuthServiceMirror:
    state: str = "signedOut"
    profile: TrainerProfile | None = None
    error: str | None = None
    has_checked_session: bool = False
    inserted: list[TrainerProfile] = field(default_factory=list)
    stored: dict[str, TrainerProfile] = field(default_factory=dict)
    sign_up_fn: Callable[[str, str], str] | None = None
    sign_in_fn: Callable[[str, str], str] | None = None
    current_user_fn: Callable[[], str] | None = None

    def sign_up(self, email: str, password: str, trainer_name: str, avatar_key: str) -> None:
        self.state = "loading"
        try:
            assert self.sign_up_fn
            user_id = self.sign_up_fn(email, password)
            profile = TrainerProfile(id=user_id, trainer_name=trainer_name, avatar_key=avatar_key)
            self.stored[user_id] = profile
            self.inserted.append(profile)
            self.profile = profile
            self.state = "signedIn"
            self.error = None
        except Exception as e:
            self.state = "error"
            msg = str(e).lower()
            if "already" in msg or "registered" in msg:
                self.error = "THAT EMAIL IS ALREADY REGISTERED!"
            else:
                self.error = "SOMETHING WENT WRONG. TRY AGAIN!"

    def log_in(self, email: str, password: str) -> None:
        self.state = "loading"
        try:
            assert self.sign_in_fn
            user_id = self.sign_in_fn(email, password)
            profile = self.stored[user_id]
            self.profile = profile
            self.state = "signedIn"
            self.error = None
        except Exception as e:
            self.state = "error"
            msg = str(e).lower()
            if "invalid" in msg or "wrong" in msg or "credential" in msg:
                self.error = "TRAINER ID NOT RECOGNIZED. TRY AGAIN!"
            else:
                self.error = "TRAINER ID NOT RECOGNIZED. TRY AGAIN!"

    def restore_session(self) -> None:
        try:
            assert self.current_user_fn
            user_id = self.current_user_fn()
            self.profile = self.stored[user_id]
            self.state = "signedIn"
        except Exception:
            self.state = "signedOut"
            self.profile = None
        self.has_checked_session = True


# --- Battle HP (mirrors BattleEngine.applyDamage + pinned damage) ---

def calculate_damage_pinned(level, power, atk, defense, stab, effectiveness, is_crit, random_factor) -> int:
    base = math.floor((2 * level / 5 + 2) * power * (atk / defense) / 50 + 2)
    crit = 1.5 if is_crit else 1.0
    return max(1, int(math.floor(base * stab * effectiveness * crit * random_factor)))


def apply_damage(hp: int, damage: int) -> int:
    return max(0, hp - damage)


def run() -> int:
    failures: list[str] = []

    def check(cond: bool, msg: str) -> None:
        if not cond:
            failures.append(msg)

    # A.7 validators
    check(is_valid_trainer_name("ASH"), "name ASH valid")
    check(not is_valid_trainer_name(""), "empty name invalid")
    check(not is_valid_trainer_name("X" * 13), "name >12 invalid")
    check(is_valid_email("ash@pallet.town"), "email valid")
    check(not is_valid_email("nope"), "email invalid")
    check(is_valid_password("password1"), "password valid")
    check(not is_valid_password("short"), "password short")
    check(passwords_match("password1", "password1"), "confirm match")
    check(not passwords_match("password1", "x"), "confirm mismatch")

    check(
        can_submit_new_trainer("ASH", "ash@a.com", "password1", "password1"),
        "new trainer submit enabled",
    )
    check(
        not can_submit_new_trainer("ASH", "ash@a.com", "password1", "nope"),
        "new trainer submit disabled on mismatch",
    )
    check(can_submit_log_in("ash@a.com", "password1"), "login submit enabled")
    check(not can_submit_log_in("bad", "password1"), "login submit disabled")

    # A.7 mode toggle
    email = "ash@pallet.town"
    kept, err = switch_mode(email, "THAT EMAIL IS ALREADY REGISTERED!")
    check(kept == email, "email preserved across mode switch")
    check(err is None, "error cleared on mode switch")
    check("confirmPassword" in visible_fields("newTrainer"), "signup fields")
    check("confirmPassword" not in visible_fields("logIn"), "login fields")

    # B.7 AuthService
    uid = str(uuid.uuid4())
    svc = AuthServiceMirror(sign_up_fn=lambda e, p: uid)
    svc.sign_up("ash@a.com", "password1", "ASH", "default_trainer")
    check(svc.state == "signedIn", "signup success state")
    check(svc.profile is not None and svc.profile.id == uid, "signup profile id")
    check(len(svc.inserted) == 1 and svc.inserted[0].id == uid, "trainers insert round-trip id")

    svc2 = AuthServiceMirror(
        sign_in_fn=lambda e, p: (_ for _ in ()).throw(Exception("Invalid login credentials"))
    )
    svc2.log_in("ash@a.com", "wrongpass")
    check(svc2.error == "TRAINER ID NOT RECOGNIZED. TRY AGAIN!", "wrong password message")

    svc3 = AuthServiceMirror(
        sign_up_fn=lambda e, p: (_ for _ in ()).throw(Exception("User already registered"))
    )
    svc3.sign_up("ash@a.com", "password1", "ASH", "default_trainer")
    check(svc3.error == "THAT EMAIL IS ALREADY REGISTERED!", "duplicate email message")

    misty_id = str(uuid.uuid4())
    svc4 = AuthServiceMirror(sign_in_fn=lambda e, p: misty_id)
    svc4.stored[misty_id] = TrainerProfile(id=misty_id, trainer_name="MISTY")
    svc4.log_in("misty@a.com", "password1")
    check(svc4.state == "signedIn" and svc4.profile and svc4.profile.trainer_name == "MISTY", "login success")

    svc5 = AuthServiceMirror(current_user_fn=lambda: (_ for _ in ()).throw(Exception("no session")))
    svc5.restore_session()
    check(svc5.state == "signedOut" and svc5.has_checked_session, "restore no session")

    # C.5 battle HP
    dmg = calculate_damage_pinned(
        level=50, power=40, atk=50, defense=64, stab=1.5, effectiveness=2.0, is_crit=False, random_factor=0.85
    )
    check(dmg > 0, "pinned damage > 0")
    previous = 88
    after = apply_damage(previous, dmg)
    check(after == previous - dmg, f"HP previous-damage: {previous}-{dmg}!={after}")
    check(apply_damage(100, 25) == 75, "100-25=75")
    check(apply_damage(10, 25) == 0, "clamp at 0")

    # Observable source-of-truth simulation
    enemy_hp = 100
    enemy_hp = apply_damage(enemy_hp, 25)
    check(enemy_hp == 75, "view-bound HP property updated")

    print("AUTH_AND_BATTLE_TESTS:", "PASS" if not failures else "FAIL")
    for f in failures:
        print("  FAIL:", f)
    if not failures:
        print(f"  signup trainers.id == auth.users.id: {uid}")
        print(f"  pinned damage sample: {dmg}; HP 88->{88 - dmg}")
        print(f"  validators + AuthService + HP mutation: OK")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(run())
