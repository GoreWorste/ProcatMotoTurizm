# -*- coding: utf-8 -*-
"""Отчёт ПР6: адаптив, сборка, публикация на VPS."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_pr4_report as base  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Otchet_Praktika_6_Adaptiv_Sborka_Publikaciya.docx"
UI = ROOT / "screenshots_report" / "pr6" / "ui"
CODE = ROOT / "screenshots_report" / "pr6" / "code"


def build_content(doc) -> None:
    base.add_h1(doc, "Содержание")
    for line in [
        "1. Введение",
        "2. Цель и задачи",
        "3. Адаптивная вёрстка",
        "4. Сборка flutter build web --release",
        "5. Публикация на VPS и DNS",
        "6. Проверка и тестирование",
        "7. Заключение",
    ]:
        base.add_p(doc, line)

    base.add_h1(doc, "1. Введение")
    base.add_p(
        doc,
        "Практическая работа № 6 завершает цикл по учебному приложению "
        "«Прокат мототехники»: интерфейс адаптируется под ширину экрана, "
        "выпускается release-сборка Flutter Web и публикуется на собственном "
        "домене, а не только локально или на GitHub Pages.",
    )

    base.add_h1(doc, "2. Цель и задачи")
    base.reset_list_num()
    base.add_num(doc, "Реализовать переломы 360 / 768 / 1280 / 1920 px.")
    base.add_num(doc, "Собрать проект: flutter build web --release, base-href /, 404.html.")
    base.add_num(doc, "Настроить DNS A-запись и раздачу статики через nginx.")
    base.add_num(doc, "Проверить deep links (go_router) и flutter test / flutter analyze.")

    base.add_h1(doc, "3. Адаптивная вёрстка")
    base.add_p(
        doc,
        "Константы в lib/core/layout_breakpoints.dart. Ниже 768 px — нижняя "
        "навигация и карточки вместо таблиц; от 768 px — NavigationRail; "
        "от 1280 px — развёрнутые подписи. Фильтры в Wrap, длинные тексты с ellipsis.",
    )
    base.add_image(
        doc,
        CODE / "layout_breakpoints.dart.png",
        caption="Рисунок 1 — Точки перелома ПР6",
    )

    base.add_h1(doc, "4. Сборка flutter build web --release")
    base.add_p(
        doc,
        "Скрипт scripts/build_production.ps1 выполняет flutter build web --release "
        "с --base-href / (корень поддомена), --dart-define=USE_API=false "
        "(демо без Node на хостинге) и копирует index.html в 404.html для SPA.",
    )
    base.add_image(
        doc,
        CODE / "build_production.ps1.png",
        caption="Рисунок 2 — Скрипт production-сборки",
    )
    base.add_image(
        doc,
        CODE / "index_html_meta.png",
        caption="Рисунок 3 — viewport и theme-color в web/index.html",
    )

    base.add_h1(doc, "5. Публикация на VPS и DNS")
    base.add_p(
        doc,
        "Поддомен motoprocatflutter.romanovivv.ru указывает A-записью на IP "
        "213.171.28.69. Содержимое build/web копируется в /var/www/motoprocatflutter "
        "(scripts/deploy_to_vps.ps1). Nginx: try_files … /index.html (файл "
        "deploy/nginx-motoprocatflutter.conf).",
    )
    base.add_image(
        doc,
        UI / "01_dns_a_record.png",
        caption="Рисунок 4 — A-запись поддомена в панели DNS",
    )
    base.add_image(
        doc,
        CODE / "nginx_motoprocat.png",
        caption="Рисунок 5 — Конфигурация nginx для SPA",
    )
    base.add_p(
        doc,
        "Публичный адрес приложения: https://motoprocatflutter.romanovivv.ru/ "
        "(после настройки nginx и при необходимости TLS).",
    )

    base.add_h1(doc, "6. Проверка и тестирование")
    base.add_bullet(doc, "flutter test — модульные и widget-тесты;")
    base.add_bullet(doc, "flutter analyze lib — статический анализ;")
    base.add_bullet(doc, "Проверка маршрутов /equipment, /clients после перезагрузки страницы;")
    base.add_bullet(doc, "DevTools → режимы 360 / 768 / 1280 px для отчётных скриншотов.")

    base.add_h1(doc, "7. Заключение")
    base.add_p(
        doc,
        "Приложение проката адаптировано под мобильные и десктопные ширины, "
        "собрано в release и опубликовано на выделенном поддомене с корректным "
        "base-href и fallback для клиентского роутинга. Для полного API-режима "
        "ПР4–ПР5 используется локальный запуск run_api_server.ps1 и run_web.ps1.",
    )

    base.add_h1(doc, "Список файлов")
    base.add_bullet(doc, "lib/core/layout_breakpoints.dart, lib/widgets/app_shell.dart")
    base.add_bullet(doc, "scripts/build_production.ps1, scripts/deploy_to_vps.ps1")
    base.add_bullet(doc, "deploy/nginx-motoprocatflutter.conf, web/index.html")


def main() -> None:
    title_path = (
        base.TITLE_TEMPLATE
        if base.TITLE_TEMPLATE.is_file()
        else base.TITLE_FALLBACK
    )
    if not title_path.is_file():
        raise SystemExit(f"Нет титульного листа: {base.TITLE_TEMPLATE}")

    doc = base.Document(str(title_path))
    base.strip_template_body(doc)
    base.trim_trailing_empty_paragraphs(doc)
    base.setup_normal_style(doc)
    base.format_title_page(doc)
    doc.add_page_break()
    base.add_h1(doc, "Практическая работа № 6. Адаптив, сборка, публикация")
    build_content(doc)

    try:
        doc.save(OUT)
        print(OUT)
    except PermissionError:
        alt = ROOT / "Otchet_Praktika_6_Adaptiv_Sborka_Publikaciya.generated.docx"
        doc.save(alt)
        print(alt)


if __name__ == "__main__":
    main()
