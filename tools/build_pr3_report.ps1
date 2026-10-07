# Полная пересборка отчёта ПР3 (сборка web + снимки + DOCX).
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "1/4 flutter build web..."
flutter build web --no-web-resources-cdn

Write-Host "2/4 код и схема..."
python tools\render_schema_image.py
python tools\render_code_images.py

Write-Host "3/4 снимки экранов (SPA-сервер на 8765)..."
$server = Start-Process -PassThru -WindowStyle Hidden python -ArgumentList "tools\spa_server.py","8765"
Start-Sleep -Seconds 2
python tools\quick_capture.py
python -c @"
import asyncio
from pathlib import Path
from playwright.async_api import async_playwright
OUT=Path('screenshots_report/pr3/ui/03_equipment_duplicate_inventory.png')
async def m():
    async with async_playwright() as p:
        b=await p.chromium.launch(headless=True)
        page=await b.new_page(viewport={'width':1400,'height':900})
        await page.goto('http://127.0.0.1:8765/equipment/new', wait_until='commit')
        await page.wait_for_timeout(10000)
        for y,t in [(180,'Test'),(260,'EQ-1001'),(500,'2024'),(580,'100'),(660,'1'),(740,'1')]:
            await page.mouse.click(700,y); await page.keyboard.type(t)
        await page.mouse.click(700,860); await page.wait_for_timeout(1500)
        await page.screenshot(path=str(OUT), full_page=True)
        await b.close()
asyncio.run(m())
"@
Stop-Process -Id $server.Id -Force

Write-Host "4/4 DOCX..."
python tools\generate_pr3_report.py
Write-Host "Готово: Otchet_Praktika_3_Formy_i_validaciya.docx"
