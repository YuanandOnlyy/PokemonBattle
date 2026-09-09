#!/usr/bin/env python3
"""Verify Supabase project reachability + trainers table CRUD using the app's publishable key."""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
import uuid

SUPABASE_URL = "https://tmlgvlstwsgmnkmwloty.supabase.co"
SUPABASE_KEY = "sb_publishable_IeNJ_xqb0AtVHIbJP34JJg_48kEu3yU"


def request(method: str, path: str, body: dict | None = None, token: str | None = None) -> tuple[int, dict | list | str]:
    url = SUPABASE_URL.rstrip("/") + path
    data = None if body is None else json.dumps(body).encode("utf-8")
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {token or SUPABASE_KEY}",
        "Content-Type": "application/json",
    }
    if method in {"POST", "PUT", "PATCH"} and "auth/v1" not in path:
        headers["Prefer"] = "return=representation"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            raw = resp.read().decode("utf-8")
            parsed: dict | list | str
            try:
                parsed = json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                parsed = raw
            return resp.status, parsed
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(raw) if raw else {"error": str(e)}
        except json.JSONDecodeError:
            parsed = raw
        return e.code, parsed


def main() -> int:
    print("=== Supabase connectivity ===")
    results = {}

    # Anonymous sign-in (required by SupabaseService)
    status, auth = request("POST", "/auth/v1/signup", {"data": {}})
    # Newer GoTrue anonymous endpoint
    if status >= 400:
        status, auth = request("POST", "/auth/v1/token?grant_type=password", {})
    if status >= 400:
        # Try dedicated anonymous sign-in used by supabase-js v2
        status, auth = request(
            "POST",
            "/auth/v1/signup",
            {"data": {}, "gotrue_meta_security": {}},
        )

    # Official anonymous: POST /auth/v1/signup with empty body + header
    if not (isinstance(auth, dict) and auth.get("access_token")):
        req = urllib.request.Request(
            SUPABASE_URL + "/auth/v1/signup",
            data=b"{}",
            headers={
                "apikey": SUPABASE_KEY,
                "Authorization": f"Bearer {SUPABASE_KEY}",
                "Content-Type": "application/json",
                "X-Supabase-Api-Version": "2024-01-01",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                auth = json.loads(resp.read().decode("utf-8"))
                status = resp.status
        except urllib.error.HTTPError as e:
            auth = json.loads(e.read().decode("utf-8", errors="replace") or "{}")
            status = e.code

    access = auth.get("access_token") if isinstance(auth, dict) else None
    user_id = None
    if isinstance(auth, dict):
        user_id = (auth.get("user") or {}).get("id") or auth.get("id")

    results["anonymous_auth"] = "PASS" if access and user_id else f"FAIL status={status} body={auth}"
    print("anonymous_auth:", results["anonymous_auth"])

    if not access or not user_id:
        # Still probe table existence with service-less anon key
        st, body = request("GET", "/rest/v1/trainers?select=id&limit=1")
        results["trainers_table"] = "PASS" if st in (200, 206) else f"FAIL status={st} body={body}"
        print("trainers_table:", results["trainers_table"])
        print("NOTE: Anonymous auth appears disabled or key rejected; cloud sync cannot be fully CRUD-tested.")
        failed = any(v.startswith("FAIL") for v in results.values())
        return 1 if failed else 0

    # CRUD against trainers
    sample = {
        "id": user_id,
        "data": {
            "name": "TestTrainer",
            "level": 1,
            "xp": 0,
            "xpToNext": 100,
            "wins": 0,
            "losses": 0,
            "streak": 0,
            "bestStreak": 0,
            "totalBattles": 0,
            "totalDamageDealt": 0,
            "totalCritHits": 0,
            "totalSuperEffective": 0,
            "favoritePokemons": {},
            "battleHistory": [],
            "achievements": [],
            "items": [],
            "settings": {
                "soundEffects": True,
                "music": True,
                "vibration": True,
                "animations": True,
                "animationSpeed": "normal",
                "consoleSkin": "dmg",
                "reducedMotion": False,
                "battleAssist": False,
            },
            "consecutiveDefeats": 0,
            "dailyQuests": [],
            "dailyQuestDate": "",
        },
    }

    st, body = request("POST", "/rest/v1/trainers", sample, token=access)
    # upsert via Prefer
    if st >= 400:
        req = urllib.request.Request(
            SUPABASE_URL + "/rest/v1/trainers",
            data=json.dumps(sample).encode("utf-8"),
            headers={
                "apikey": SUPABASE_KEY,
                "Authorization": f"Bearer {access}",
                "Content-Type": "application/json",
                "Prefer": "resolution=merge-duplicates,return=representation",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                st = resp.status
                body = json.loads(resp.read().decode("utf-8") or "[]")
        except urllib.error.HTTPError as e:
            st = e.code
            body = e.read().decode("utf-8", errors="replace")

    results["trainers_create"] = "PASS" if st in (200, 201) else f"FAIL status={st} body={body}"
    print("trainers_create:", results["trainers_create"])

    st, body = request("GET", f"/rest/v1/trainers?id=eq.{user_id}&select=id,data", token=access)
    ok_read = st == 200 and isinstance(body, list) and len(body) >= 1
    results["trainers_read"] = "PASS" if ok_read else f"FAIL status={st} body={body}"
    print("trainers_read:", results["trainers_read"])

    sample["data"]["name"] = "TestTrainerUpdated"
    sample["data"]["wins"] = 3
    req = urllib.request.Request(
        SUPABASE_URL + f"/rest/v1/trainers?id=eq.{user_id}",
        data=json.dumps({"data": sample["data"]}).encode("utf-8"),
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {access}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        },
        method="PATCH",
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            st = resp.status
            body = json.loads(resp.read().decode("utf-8") or "[]")
    except urllib.error.HTTPError as e:
        st = e.code
        body = e.read().decode("utf-8", errors="replace")
    results["trainers_update"] = "PASS" if st in (200, 204) else f"FAIL status={st} body={body}"
    print("trainers_update:", results["trainers_update"])

    st, body = request("GET", f"/rest/v1/trainers?id=eq.{user_id}&select=data", token=access)
    persisted = False
    if st == 200 and isinstance(body, list) and body:
        persisted = body[0].get("data", {}).get("name") == "TestTrainerUpdated"
    results["trainers_persist"] = "PASS" if persisted else f"FAIL status={st} body={body}"
    print("trainers_persist:", results["trainers_persist"])

    # Cleanup delete
    req = urllib.request.Request(
        SUPABASE_URL + f"/rest/v1/trainers?id=eq.{user_id}",
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {access}",
        },
        method="DELETE",
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            st = resp.status
            body = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        st = e.code
        body = e.read().decode("utf-8", errors="replace")
    results["trainers_delete"] = "PASS" if st in (200, 204) else f"FAIL status={st} body={body}"
    print("trainers_delete:", results["trainers_delete"])

    failed = [k for k, v in results.items() if not str(v).startswith("PASS")]
    print("SUMMARY:", "PASS" if not failed else f"FAIL ({', '.join(failed)})")
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
