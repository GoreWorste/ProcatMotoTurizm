# -*- coding: utf-8 -*-
"""Снимки UI для отчёта ПР4 (Flutter Web + mock API на 8080)."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots_report" / "pr4" / "ui"
BASE = os.environ.get("PR4_WEB_BASE", "http://localhost:5555")
API = "http://localhost:8080/api"
WAIT_FLUTTER_MS = 22000


def _ensure_a11y(page) -> None:
    btn = page.get_by_role("button", name="Enable accessibility")
    if btn.count():
        try:
            btn.click(timeout=3000)
        except Exception:
            pass
    page.wait_for_timeout(1500)


def _render_api_panel(path: Path, title: str, body: str) -> None:
    from PIL import Image, ImageDraw, ImageFont

    lines = [title, ""] + body.splitlines()

    def _font(size: int = 14):
        for name in (
            r"C:\Windows\Fonts\arial.ttf",
            r"C:\Windows\Fonts\segoeui.ttf",
            "arial.ttf",
        ):
            try:
                return ImageFont.truetype(name, size)
            except OSError:
                continue
        return ImageFont.load_default()

    font = _font()
    line_h = 18
    w, h = 1080, max(200, 40 + line_h * len(lines))
    img = Image.new("RGB", (w, h), (245, 245, 245))
    draw = ImageDraw.Draw(img)
    for i, line in enumerate(lines):
        draw.text((20, 16 + i * line_h), line, fill=(20, 20, 20), font=font)
    img.save(path)


def _wait_data(page) -> None:
    try:
        page.wait_for_function(
            """() => {
              const t = document.body?.innerText || '';
              return /всего [1-9]/.test(t) || t.includes('Не удалось') || t.includes('Сервер');
            }""",
            timeout=45000,
        )
    except Exception:
        page.wait_for_timeout(5000)
    page.wait_for_timeout(800)


def _shot(page, name: str, url: str | None = None, wait_ms: int = WAIT_FLUTTER_MS) -> Path:
    if url:
        page.goto(url, wait_until="domcontentloaded")
    page.wait_for_timeout(wait_ms)
    _ensure_a11y(page)
    _wait_data(page)
    path = OUT / name
    page.screenshot(path=str(path), full_page=True)
    print(path)
    return path


def _fill_equipment_duplicate_form(page) -> None:
    page.goto(f"{BASE}/equipment/new", wait_until="domcontentloaded")
    page.wait_for_timeout(3500)
    _ensure_a11y(page)

    page.get_by_label("Название").fill("Тестовая палатка для отчёта")
    page.get_by_label("Инвентарный номер").fill("EQ-1001")
    page.get_by_label("Год покупки").fill("2024")
    page.get_by_label("Тариф за сутки (₽)").fill("500")
    page.get_by_label("Всего единиц").fill("2")
    page.get_by_label("Доступно").fill("2")

    # Категория и бренд — первые доступные в выпадающих списках.
    page.locator("flutter-view").click(position={"x": 400, "y": 420})
    page.wait_for_timeout(300)
    for text in ("Палатки", "Tramp"):
        opt = page.get_by_text(text, exact=True)
        if opt.count():
            opt.first.click(timeout=2000)
            page.wait_for_timeout(400)

    # Тег — chip «лето» или первый.
    tag = page.get_by_text("лето", exact=True)
    if tag.count():
        tag.first.click(timeout=2000)

    page.get_by_role("button", name="Создать").click(timeout=5000)
    page.wait_for_timeout(2000)


def _brand_hard_delete_conflict(page) -> None:
    page.goto(f"{BASE}/brands/1", wait_until="domcontentloaded")
    page.wait_for_timeout(3000)
    _ensure_a11y(page)

    soft = page.get_by_role("button", name="Логическое удаление")
    if soft.count():
        soft.click()
        page.get_by_role("button", name="Удалить").click(timeout=3000)
        page.wait_for_timeout(1500)

    hard = page.get_by_role("button", name="Физическое удаление")
    hard.click(timeout=5000)
    page.get_by_role("button", name="Удалить навсегда").click(timeout=3000)
    page.wait_for_timeout(2000)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)

    try:
        import urllib.request

        urllib.request.urlopen(f"{API}/__health", timeout=3)
    except Exception:
        print("Запустите mock API: .\\scripts\\run_api_server.ps1", file=sys.stderr)
        return 1

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1440, "height": 900},
            locale="ru-RU",
        )
        page = context.new_page()

        # 1 — проверка API (для отчёта, не Flutter).
        health = OUT / "00_api_health.png"
        page.goto(f"{API}/__health", wait_until="domcontentloaded")
        page.set_content(
            "<pre style='font:14px monospace;padding:24px'>"
            + json.dumps(
                json.loads(page.locator("body").inner_text() or "{}"),
                ensure_ascii=False,
                indent=2,
            )
            + "</pre>"
        )
        page.screenshot(path=str(health), full_page=True)
        print(health)

        _shot(page, "01_equipment_list.png", f"{BASE}/equipment?page=1&size=10")
        _shot(
            page,
            "02_equipment_filters.png",
            f"{BASE}/equipment?categoryId=1&sort=dailyRate,desc&page=1&size=10",
        )
        _shot(page, "03_clients_list.png", f"{BASE}/clients?page=1&size=10")
        _shot(page, "07_equipment_form_new.png", f"{BASE}/equipment/new")
        _shot(page, "08_brands_list.png", f"{BASE}/brands?page=1&size=10")

        import urllib.error
        import urllib.request

        dup_body = json.dumps(
            {
                "name": "Тест",
                "inventoryNumber": "EQ-1001",
                "categoryId": 1,
                "brandId": 1,
                "purchaseYear": 2024,
                "dailyRate": 500,
                "condition": "хорошее",
                "unitsTotal": 2,
                "unitsAvailable": 2,
                "tagIds": [2],
            },
            ensure_ascii=False,
        ).encode("utf-8")
        req = urllib.request.Request(
            f"{API}/equipment",
            data=dup_body,
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        try:
            urllib.request.urlopen(req)
        except urllib.error.HTTPError as e:
            text = e.read().decode("utf-8", errors="replace")
            panel = OUT / "04_api_422_duplicate.png"
            _render_api_panel(
                panel,
                "POST /api/equipment -> 422 (дубликат inventoryNumber)",
                f"HTTP {e.code}\n\n{text}",
            )
            print(panel)

        del_req = urllib.request.Request(
            f"{API}/brands/1?hard=true",
            method="DELETE",
        )
        try:
            urllib.request.urlopen(del_req)
        except urllib.error.HTTPError as e:
            text = e.read().decode("utf-8", errors="replace")
            panel = OUT / "05_api_409_brand.png"
            _render_api_panel(
                panel,
                "DELETE /api/brands/1?hard=true -> 409 (есть оборудование)",
                f"HTTP {e.code}\n\n{text}",
            )
            print(panel)

        try:
            _fill_equipment_duplicate_form(page)
            page.screenshot(
                path=str(OUT / "04_equipment_422_duplicate.png"),
                full_page=True,
            )
            print(OUT / "04_equipment_422_duplicate.png")
        except Exception as e:
            print(f"Пропуск 422: {e}", file=sys.stderr)

        try:
            _brand_hard_delete_conflict(page)
            page.screenshot(
                path=str(OUT / "05_brand_409_conflict.png"),
                full_page=True,
            )
            print(OUT / "05_brand_409_conflict.png")
        except Exception as e:
            print(f"Пропуск 409: {e}", file=sys.stderr)

        # Сбой сети: блокируем API на новой вкладке.
        fail_page = context.new_page()
        fail_page.route("**/localhost:8080/**", lambda route: route.abort())
        fail_page.goto(f"{BASE}/equipment", wait_until="domcontentloaded")
        fail_page.wait_for_timeout(WAIT_FLUTTER_MS)
        _ensure_a11y(fail_page)
        fail_path = OUT / "06_list_network_error.png"
        fail_page.screenshot(path=str(fail_path), full_page=True)
        print(fail_path)

        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
