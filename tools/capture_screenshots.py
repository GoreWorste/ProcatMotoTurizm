# -*- coding: utf-8 -*-
"""Скриншоты UI для отчёта (все обязательные состояния)."""

from __future__ import annotations

import html
from pathlib import Path

from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:7357"
OUT = Path(__file__).resolve().parents[1] / "screenshots_report"
OUT.mkdir(exist_ok=True)

ADDRESS_URL = (
    f"{BASE}/equipment?search=%D0%BF%D0%B0%D0%BB%D0%B0%D1%82%D0%BA%D0%B0"
    "&categoryId=1&sort=dailyRate,desc&page=1&size=10"
)


def wait_ready(page, extra_ms: int = 2800) -> None:
    page.wait_for_selector("flutter-view", timeout=60000)
    page.wait_for_timeout(extra_ms)


def inject_address_bar(page, url: str) -> None:
    page.evaluate(
        """(url) => {
            const old = document.getElementById('report-url-bar');
            if (old) old.remove();
            const bar = document.createElement('div');
            bar.id = 'report-url-bar';
            bar.textContent = url;
            bar.style.cssText =
              'position:fixed;top:0;left:0;right:0;z-index:999999;' +
              'height:34px;background:#f1f3f4;border-bottom:1px solid #dadce0;' +
              'font:13px Consolas,monospace;line-height:34px;padding:0 12px;color:#202124;';
            document.body.style.marginTop = '34px';
            document.documentElement.insertBefore(bar, document.body);
        }""",
        url,
    )


def shot(page, path: Path, full_page: bool = False) -> None:
    page.screenshot(path=str(path), full_page=full_page)


def main() -> None:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)

        # 1 — таблица
        page = browser.new_page(viewport={"width": 1280, "height": 900})
        page.goto(f"{BASE}/equipment?sort=name,asc&page=1&size=10", wait_until="networkidle")
        wait_ready(page)
        shot(page, OUT / "fig01_table_list.png")
        page.close()

        # 2 — карточки (узкое окно)
        page = browser.new_page(viewport={"width": 390, "height": 844})
        page.goto(f"{BASE}/equipment?sort=name,asc&page=1&size=10", wait_until="networkidle")
        wait_ready(page)
        shot(page, OUT / "fig02_card_list_mobile.png", full_page=True)
        page.close()

        # 3 — фильтры
        page = browser.new_page(viewport={"width": 1280, "height": 900})
        page.goto(
            f"{BASE}/equipment?categoryId=4&brandId=2&dailyRateFrom=3000"
            f"&dailyRateTo=5000&sort=dailyRate,desc&page=1&size=10",
            wait_until="networkidle",
        )
        wait_ready(page)
        shot(page, OUT / "fig03_filters_applied.png")
        page.close()

        # 4 — выделение нескольких записей
        page = browser.new_page(viewport={"width": 1280, "height": 900})
        page.goto(f"{BASE}/equipment?sort=name,asc&page=1&size=10", wait_until="networkidle")
        wait_ready(page)
        for y in (268, 318, 368):
            page.mouse.click(42, y)
            page.wait_for_timeout(200)
        shot(page, OUT / "fig04_multi_selection.png")
        page.close()

        # 5 — пустой результат
        page = browser.new_page(viewport={"width": 1280, "height": 900})
        page.goto(
            f"{BASE}/equipment?search=zzzzempty&sort=name,asc&page=1&size=10",
            wait_until="networkidle",
        )
        wait_ready(page)
        shot(page, OUT / "fig05_empty_result.png")
        page.close()

        # 6 — ошибка
        page = browser.new_page(viewport={"width": 1280, "height": 900})
        page.goto(
            f"{BASE}/equipment?search=__error__&sort=name,asc&page=1&size=10",
            wait_until="networkidle",
        )
        wait_ready(page, 3200)
        shot(page, OUT / "fig06_error_state.png")
        page.close()

        # 7 — адресная строка с параметрами
        page = browser.new_page(viewport={"width": 1280, "height": 900})
        page.goto(ADDRESS_URL, wait_until="networkidle")
        wait_ready(page)
        inject_address_bar(
            page,
            "/equipment?search=палатка&categoryId=1&sort=dailyRate,desc&page=1&size=10",
        )
        page.wait_for_timeout(400)
        shot(page, OUT / "fig07_url_query_params.png")
        page.close()

        # 8 — карточка оборудования
        page = browser.new_page(viewport={"width": 1280, "height": 900})
        page.goto(f"{BASE}/equipment/7", wait_until="networkidle")
        wait_ready(page, 4500)
        shot(page, OUT / "fig08_equipment_detail.png", full_page=False)
        page.close()

        # 9 — загрузка (удлинённая задержка репозитория через __slow_load__)
        page = browser.new_page(viewport={"width": 1280, "height": 900})
        page.goto(
            f"{BASE}/equipment?search=__slow_load__&sort=name,asc&page=1&size=10",
            wait_until="commit",
        )
        page.wait_for_timeout(1200)
        shot(page, OUT / "fig09_loading_state.png", full_page=False)
        page.close()

        browser.close()
        print("Screenshots saved to", OUT)


if __name__ == "__main__":
    main()
