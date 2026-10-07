import asyncio
from pathlib import Path

from playwright.async_api import async_playwright

OUT = Path(__file__).resolve().parents[1] / "screenshots_report" / "pr3" / "ui"
BASE = "http://127.0.0.1:8765"

URLS = [
    ("01_equipment_form_relations.png", "/equipment/new"),
    ("04_client_form_rental_card.png", "/clients/new"),
    ("05_brand_delete_blocked.png", "/brands"),
    ("09_equipment_list_pr2_features.png", "/equipment"),
    ("08_categories_search_pagination.png", "/categories"),
    ("06_persistence_before_reload.png", "/equipment?search=Tramp"),
]


async def main():
    OUT.mkdir(parents=True, exist_ok=True)
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1400, "height": 900})
        for fname, path in URLS:
            await page.goto(BASE + path, wait_until="commit", timeout=60000)
            await page.wait_for_timeout(10000)
            await page.screenshot(path=str(OUT / fname), full_page=True)
            print(OUT / fname)
        await page.goto(BASE + "/equipment/new", wait_until="commit")
        await page.wait_for_timeout(8000)
        await page.mouse.click(700, 860)
        await page.wait_for_timeout(1500)
        await page.screenshot(path=str(OUT / "02_equipment_validation_errors.png"), full_page=True)
        print(OUT / "02_equipment_validation_errors.png")
        await page.reload(wait_until="commit")
        await page.wait_for_timeout(8000)
        await page.screenshot(path=str(OUT / "07_persistence_after_reload.png"), full_page=True)
        print(OUT / "07_persistence_after_reload.png")
        await browser.close()


asyncio.run(main())
