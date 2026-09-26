# -*- coding: utf-8 -*-
"""PNG-изображения исходного кода (ветка dev, каталог lib)."""

from __future__ import annotations

import html
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots_report" / "code"
OUT.mkdir(parents=True, exist_ok=True)

# (путь, имя файла png, подпись 2–3 слова, описание до 10 слов)
CODE_ITEMS: list[tuple[str, str, str, str]] = [
    ("lib/main.dart", "code_main.png", "Точка входа", "Router, provider и URL strategy"),
    ("lib/models/equipment.dart", "code_equipment_model.png", "Модель Equipment", "Immutable сущность и copyWith"),
    ("lib/models/client.dart", "code_client_model.png", "Модель Client", "Данные клиента проката"),
    ("lib/models/page_result.dart", "code_page_result.png", "PageResult", "Пагинация и totalPages"),
    ("lib/models/equipment_query.dart", "code_equipment_query.png", "EquipmentQuery", "Фильтры и сброс page"),
    ("lib/models/client_query.dart", "code_client_query.png", "ClientQuery", "Условия отбора клиентов"),
    ("lib/repositories/in_memory_equipment_repository.dart", "code_repo_equipment.png", "Репозиторий Equipment", "Поиск, фильтры, find"),
    ("lib/repositories/in_memory_client_repository.dart", "code_repo_client.png", "Репозиторий Client", "In-memory выборка клиентов"),
    ("lib/state/equipment_list_notifier.dart", "code_notifier_equipment.png", "Notifier оборудования", "Загрузка, query, selected"),
    ("lib/state/client_list_notifier.dart", "code_notifier_client.png", "Notifier клиентов", "Состояние списка клиентов"),
    ("lib/routing/query_params.dart", "code_query_params.png", "Параметры URL", "Сериализация query в адрес"),
    ("lib/widgets/entity_table.dart", "code_entity_table.png", "EntityTable", "Обобщённая таблица сущностей"),
    ("lib/screens/equipment_list_screen.dart", "code_screen_equipment_list.png", "Экран списка", "Таблица, фильтры, URL"),
    ("lib/screens/equipment_detail_screen.dart", "code_screen_equipment_detail.png", "Экран карточки", "Детальный просмотр Equipment"),
    ("lib/screens/client_list_screen.dart", "code_screen_client_list.png", "Список клиентов", "Поиск и пагинация"),
    ("lib/screens/client_detail_screen.dart", "code_screen_client_detail.png", "Карточка клиента", "Просмотр полей Client"),
    ("pubspec.yaml", "code_pubspec.png", "Зависимости", "provider и go_router"),
    (
        "lib/repositories/in_memory_equipment_repository.dart",
        "code_delete_many_fix.png",
        "deleteMany fix",
        "Исправление index >= 0",
    ),
]

# Для deleteMany — только фрагмент
DELETE_MANY_SNIPPET = """// Было (ошибка):
if (index > 0) {
  _items.removeAt(index);
}

// Стало:
if (index >= 0) {
  _items.removeAt(index);
}"""


def render_code_png(playwright, source: str, out_path: Path) -> None:
    safe = html.escape(source)
    html_page = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
body {{ margin:0; background:#1e1e1e; }}
pre {{
  margin:0; padding:14px; color:#d4d4d4; font:11px/1.35 Consolas, monospace;
  white-space: pre-wrap; word-break: break-word;
}}
</style></head><body><pre>{safe}</pre></body></html>"""
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": 920, "height": 720})
    page.set_content(html_page, wait_until="networkidle")
    height = page.evaluate("() => document.body.scrollHeight")
    page.set_viewport_size({"width": 920, "height": min(max(height + 20, 200), 4000)})
    page.screenshot(path=str(out_path), full_page=True)
    browser.close()


def main() -> None:
    with sync_playwright() as p:
        for rel, png_name, _title, _desc in CODE_ITEMS:
            out = OUT / png_name
            if png_name == "code_delete_many_fix.png":
                render_code_png(p, DELETE_MANY_SNIPPET, out)
                print("OK", png_name)
                continue
            path = ROOT / rel.replace("/", "\\")
            text = path.read_text(encoding="utf-8")
            render_code_png(p, text, out)
            print("OK", png_name)
    print("Code images:", OUT)


if __name__ == "__main__":
    main()
