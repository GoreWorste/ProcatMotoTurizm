# -*- coding: utf-8 -*-
"""Снимки экранов ПР3 (Playwright + локальная сборка web)."""
from __future__ import annotations

import asyncio
import subprocess
import sys
import time
from pathlib import Path

from playwright.async_api import async_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots_report" / "pr3" / "ui"
OUT.mkdir(parents=True, exist_ok=True)
PORT = 8765
BASE = f"http://127.0.0.1:{PORT}"


def ensure_build() -> None:
    if (ROOT / "build" / "web" / "index.html").is_file():
        return
    import shutil

    flutter = shutil.which("flutter")
    if not flutter:
        raise SystemExit("Сначала выполните: flutter build web --no-web-resources-cdn")
    subprocess.run(
        [flutter, "build", "web", "--no-web-resources-cdn"],
        cwd=ROOT,
        check=True,
        shell=flutter.lower().endswith(".bat"),
    )


def start_server() -> subprocess.Popen:
    return subprocess.Popen(
        [sys.executable, str(ROOT / "tools" / "spa_server.py"), str(PORT)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


async def wait_flutter(page) -> None:
    try:
        await page.wait_for_selector("flt-glass-pane", timeout=90000)
    except Exception:
        pass
    await page.wait_for_timeout(6000)


async def shot(page, name: str) -> None:
    path = OUT / name
    await page.screenshot(path=str(path), full_page=True)
    print(path)


async def click_xy(page, x: int, y: int) -> None:
    await page.mouse.click(x, y)
    await page.wait_for_timeout(200)


async def type_text(page, text: str) -> None:
    await page.keyboard.type(text, delay=30)


async def main() -> None:
    ensure_build()
    server = start_server()
    time.sleep(1)
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(
                headless=True,
                args=["--enable-webgl", "--disable-dev-shm-usage"],
            )
            page = await browser.new_page(viewport={"width": 1400, "height": 920})
            page.set_default_timeout(60000)

            await page.goto(f"{BASE}/equipment/new", wait_until="domcontentloaded")
            await wait_flutter(page)
            await shot(page, "01_equipment_form_relations.png")

            await click_xy(page, 700, 850)
            await page.wait_for_timeout(1000)
            await shot(page, "02_equipment_validation_errors.png")

            await click_xy(page, 700, 180)
            await type_text(page, "Test uniq")
            await click_xy(page, 700, 260)
            await type_text(page, "EQ-1001")
            await click_xy(page, 700, 500)
            await type_text(page, "2024")
            await click_xy(page, 700, 580)
            await type_text(page, "100")
            await click_xy(page, 700, 660)
            await type_text(page, "1")
            await click_xy(page, 700, 740)
            await type_text(page, "1")
            await click_xy(page, 700, 850)
            await page.wait_for_timeout(1000)
            await shot(page, "03_equipment_duplicate_inventory.png")

            await page.goto(f"{BASE}/clients/new", wait_until="domcontentloaded")
            await wait_flutter(page)
            await shot(page, "04_client_form_rental_card.png")

            await page.goto(f"{BASE}/brands", wait_until="domcontentloaded")
            await wait_flutter(page)
            await click_xy(page, 1280, 300)
            await page.wait_for_timeout(500)
            await click_xy(page, 880, 520)
            await page.wait_for_timeout(1500)
            await shot(page, "05_brand_delete_blocked.png")

            await page.goto(f"{BASE}/equipment", wait_until="domcontentloaded")
            await wait_flutter(page)
            await shot(page, "09_equipment_list_pr2_features.png")

            await page.goto(f"{BASE}/equipment?search=Tramp", wait_until="domcontentloaded")
            await wait_flutter(page)
            await shot(page, "06_persistence_before_reload.png")
            await page.reload(wait_until="domcontentloaded")
            await wait_flutter(page)
            await shot(page, "07_persistence_after_reload.png")

            await page.goto(f"{BASE}/categories?search=Палат", wait_until="domcontentloaded")
            await wait_flutter(page)
            await shot(page, "08_categories_search_pagination.png")

            await browser.close()
    finally:
        server.terminate()
        server.wait(timeout=5)


if __name__ == "__main__":
    asyncio.run(main())
