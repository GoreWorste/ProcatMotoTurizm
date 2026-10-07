# -*- coding: utf-8 -*-
"""Снимки UI для отчёта ПР5 (авторизация и роли)."""
from __future__ import annotations

import os
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots_report" / "pr5" / "ui"
BASE = os.environ.get("PR5_WEB_BASE", "http://localhost:5555")
API = "http://localhost:8080/api"


def _ensure_a11y(page) -> None:
    btn = page.get_by_role("button", name="Enable accessibility")
    if btn.count():
        try:
            btn.click(timeout=3000)
        except Exception:
            pass
    page.wait_for_timeout(1200)


def _api_login(username: str, password: str) -> dict:
    import json
    import urllib.request

    body = json.dumps({"username": username, "password": password}).encode("utf-8")
    req = urllib.request.Request(
        f"{API}/auth/login",
        data=body,
        method="POST",
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))


def _session_login(page, username: str, password: str) -> None:
    """В headless Flutter Web форма часто без a11y — кладём токены как SharedPreferences."""
    tokens = _api_login(username, password)
    page.goto(BASE, wait_until="domcontentloaded")
    page.evaluate(
        """(t) => {
          localStorage.setItem('flutter.auth_access_token', t.access);
          localStorage.setItem('flutter.auth_refresh_token', t.refresh);
        }""",
        {"access": tokens["accessToken"], "refresh": tokens["refreshToken"]},
    )
    page.goto(f"{BASE}/equipment", wait_until="domcontentloaded")
    page.wait_for_timeout(6000)
    _ensure_a11y(page)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    try:
        import urllib.request

        urllib.request.urlopen(f"{API}/__health", timeout=3)
    except Exception:
        print("Запустите API: .\\scripts\\run_api_server.ps1", file=sys.stderr)
        return 1

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1440, "height": 900},
            locale="ru-RU",
        )
        page = context.new_page()

        page.goto(f"{BASE}/equipment", wait_until="domcontentloaded")
        page.wait_for_timeout(4000)
        _ensure_a11y(page)
        p1 = OUT / "01_login_redirect.png"
        page.screenshot(path=str(p1), full_page=True)
        print(p1)

        _session_login(page, "viewer", "viewer123")
        p2 = OUT / "02_equipment_viewer.png"
        page.screenshot(path=str(p2), full_page=True)
        print(p2)

        page.goto(f"{BASE}/admin/users", wait_until="domcontentloaded")
        page.wait_for_timeout(3000)
        _ensure_a11y(page)
        p3 = OUT / "03_forbidden_403.png"
        page.screenshot(path=str(p3), full_page=True)
        print(p3)

        _session_login(page, "admin", "admin123")
        page.goto(f"{BASE}/admin/users", wait_until="domcontentloaded")
        page.wait_for_timeout(4000)
        _ensure_a11y(page)
        p4 = OUT / "04_admin_users.png"
        page.screenshot(path=str(p4), full_page=True)
        print(p4)

        storage = page.evaluate(
            """() => ({
              auth_access_token: localStorage.getItem('flutter.auth_access_token'),
              auth_refresh_token: localStorage.getItem('flutter.auth_refresh_token'),
              keys: Object.keys(localStorage).filter(k => k.includes('auth')),
            })"""
        )
        panel = OUT / "05_local_storage_tokens.png"
        page.set_content(
            "<pre style='font:14px monospace;padding:24px'>"
            + str(storage)
            + "\n\n(В Flutter Web токены в shared_preferences → localStorage)</pre>"
        )
        page.screenshot(path=str(panel), full_page=True)
        print(panel)

        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
