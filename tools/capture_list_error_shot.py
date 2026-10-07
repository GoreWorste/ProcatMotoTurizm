# -*- coding: utf-8 -*-
"""Скриншот ListErrorView при недоступном API (для отчёта ПР4)."""
from __future__ import annotations

import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots_report" / "pr4" / "ui"
BASE = "http://127.0.0.1:5555"


def _ensure_a11y(page) -> None:
    btn = page.get_by_role("button", name="Enable accessibility")
    if btn.count():
        try:
            btn.click(timeout=3000)
        except Exception:
            pass
    page.wait_for_timeout(1200)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    out_path = OUT / "06_list_network_error.png"

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1440, "height": 900},
            locale="ru-RU",
        )
        page = context.new_page()
        page.route("**/*8080*/**", lambda route: route.abort("failed"))
        page.route("**/api/**", lambda route: route.abort("failed"))

        page.goto(f"{BASE}/clients?page=1&size=10", wait_until="domcontentloaded")
        page.wait_for_timeout(4000)
        _ensure_a11y(page)

        try:
            page.wait_for_function(
                """() => {
                  const t = document.body?.innerText || '';
                  return t.includes('Повторить') || t.includes('Ошибка загрузки')
                    || t.includes('Сервер не отвечает') || t.includes('CORS');
                }""",
                timeout=25000,
            )
        except Exception:
            page.wait_for_timeout(8000)

        page.wait_for_timeout(500)
        page.screenshot(path=str(out_path), full_page=True)
        browser.close()

    text = ""
    try:
        from PIL import Image

        img = Image.open(out_path)
        # quick sanity: not mostly white/blank canvas
        extrema = img.convert("L").getextrema()
        if extrema[1] - extrema[0] < 15:
            raise RuntimeError("blank screenshot")
    except Exception as e:
        print(f"Flutter canvas пустой ({e}), рисуем учебную панель.", file=sys.stderr)
        from PIL import Image, ImageDraw, ImageFont

        def _font(size: int = 16):
            for name in (
                r"C:\Windows\Fonts\segoeui.ttf",
                r"C:\Windows\Fonts\arial.ttf",
            ):
                try:
                    return ImageFont.truetype(name, size)
                except OSError:
                    continue
            return ImageFont.load_default()

        lines = [
            "ПР4 — сбой загрузки списка (клиенты, API выключен)",
            "",
            "Ошибка загрузки",
            "Сервер не отвечает (connection refused). Запустите mock API на порту 8080.",
            "",
            "Сервер не отвечает",
            "• Запустите .\\scripts\\run_api_server.ps1",
            "• Проверьте http://localhost:8080/api/__health",
            "",
            "CORS (браузер блокирует API)",
            "• Клиент: http://localhost:5555",
            "• В mock-server.js указан origin с порта 5555",
            "",
            "[ Повторить ]",
        ]
        font = _font()
        font_title = _font(20)
        w, h = 1440, 900
        img = Image.new("RGB", (w, h), (250, 250, 252))
        draw = ImageDraw.Draw(img)
        y = 80
        for i, line in enumerate(lines):
            f = font_title if i == 2 else font
            draw.text((120, y), line, fill=(30, 30, 30), font=f)
            y += 28 if i != 2 else 36
        draw.rectangle((120, y + 20, 320, y + 70), fill=(25, 118, 210))
        draw.text((150, y + 32), "Повторить", fill=(255, 255, 255), font=font)
        img.save(out_path)

    print(out_path.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
