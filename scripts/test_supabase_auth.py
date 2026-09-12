#!/usr/bin/env python3
"""Verify Supabase Auth + public.trainers against the columnar migration schema."""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
import uuid

SUPABASE_URL = "https://tmlgvlstwsgmnkmwloty.supabase.co"
SUPABASE_KEY = "sb_publishable_IeNJ_xqb0AtVHIbJP34JJg_48kEu3yU"


def request(method: str, path: str, body: dict | None = None, token: str | None = None) -> tuple[int, object]:
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
            try:
                return resp.status, json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                return resp.status, raw
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            return e.code, json.loads(raw) if raw else {"error": str(e)}
        except json.JSONDecodeError:
            return e.code, raw


def signup_email(email: str, password: str) -> tuple[int, dict]:
    status, body = request(
        "POST",
        "/auth/v1/signup",
        {"email": email, "password": password},
    )
    return status, body if isinstance(body, dict) else {"raw": body}


def main() -> int:
    print("=== Supabase auth + trainers (columnar schema) ===")
    results: dict[str, str] = {}

    email = f"audit_{uuid.uuid4().hex[:10]}@example.com"
    password = "password12345"
    status, auth = signup_email(email, password)
    access = auth.get("access_token")
    user = auth.get("user") or {}
    user_id = user.get("id")
    session_ok = bool(access and user_id)
    results["email_signup"] = "PASS" if session_ok else f"FAIL status={status} body={auth}"
    print("email_signup:", results["email_signup"])
    if not session_ok:
        # Common: Confirm email enabled → user created, no session
        if user_id and not access:
            results["email_signup"] = "FAIL (user created but no session — disable Confirm email in Auth settings)"
            print("NOTE:", results["email_signup"])
        print("SUMMARY: FAIL")
        return 1

    row = {
        "id": user_id,
        "trainer_name": "AUDIT",
        "avatar_key": "default_trainer",
        "level": 1,
        "xp": 0,
        "wins": 0,
        "losses": 0,
        "win_streak": 0,
        "game_data": {"name": "AUDIT", "level": 1, "avatarKey": "default_trainer"},
    }
    st, body = request("POST", "/rest/v1/trainers", row, token=access)
    if st >= 400:
        # Maybe legacy jsonb `data` schema still present
        legacy = {"id": user_id, "data": row["game_data"]}
        st2, body2 = request("POST", "/rest/v1/trainers", legacy, token=access)
        if st2 in (200, 201):
            results["trainers_insert"] = (
                "PASS (legacy data jsonb schema — run supabase/migrations/0001_trainers.sql to upgrade)"
            )
            print("trainers_insert:", results["trainers_insert"])
            # cleanup
            request("DELETE", f"/rest/v1/trainers?id=eq.{user_id}", token=access)
            print("SUMMARY: PASS (legacy schema)")
            return 0
        results["trainers_insert"] = f"FAIL status={st} body={body}"
    else:
        results["trainers_insert"] = "PASS"
    print("trainers_insert:", results["trainers_insert"])

    st, body = request(
        "GET",
        f"/rest/v1/trainers?id=eq.{user_id}&select=id,trainer_name,avatar_key,game_data",
        token=access,
    )
    ok = (
        st == 200
        and isinstance(body, list)
        and body
        and body[0].get("id") == user_id
        and body[0].get("trainer_name") == "AUDIT"
    )
    results["trainers_roundtrip"] = "PASS" if ok else f"FAIL status={st} body={body}"
    print("trainers_roundtrip:", results["trainers_roundtrip"])

    request("DELETE", f"/rest/v1/trainers?id=eq.{user_id}", token=access)

    failed = [k for k, v in results.items() if not str(v).startswith("PASS")]
    print("SUMMARY:", "PASS" if not failed else f"FAIL ({', '.join(failed)})")
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
