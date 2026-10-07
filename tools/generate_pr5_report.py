# -*- coding: utf-8 -*-
"""Отчёт ПР5: авторизация, роли, JWT, redirect."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_pr4_report as base  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Otchet_Praktika_5_Avtorizaciya_Roli.docx"
UI = ROOT / "screenshots_report" / "pr5" / "ui"
CODE = ROOT / "screenshots_report" / "pr5" / "code"


def build_content(doc) -> None:
    base.add_h1(doc, "Содержание")
    for line in [
        "1. Введение",
        "2. Цель и задачи",
        "3. Роли в предметной области",
        "4. AuthNotifier и хранение токенов",
        "5. GoRouter: redirect и защита маршрутов",
        "6. Скрытие действий в UI и экран 403",
        "7. JWT на mock API и проверка прав",
        "8. Обновление access-токена по 401",
        "9. Таймаут неактивности",
        "10. Тестирование и демонстрация",
        "11. Заключение",
    ]:
        base.add_p(doc, line)

    base.add_h1(doc, "1. Введение")
    base.add_p(
        doc,
        "Практическая работа № 5 продолжает развитие Flutter Web-приложения "
        "«Прокат мототехники» после подключения REST API (ПР4). Добавлены "
        "аутентификация по JWT, ролевая модель доступа, защита маршрутов "
        "go_router и учебный backend с проверкой Authorization на каждом запросе.",
    )

    base.add_h1(doc, "2. Цель и задачи")
    base.add_p(
        doc,
        "Цель — реализовать вход, регистрацию, хранение пары access/refresh в "
        "shared_preferences (localStorage), разграничение прав viewer / manager / admin "
        "и согласовать UI с ответами API 401/403.",
    )
    base.reset_list_num()
    base.add_num(doc, "Реализовать AuthNotifier с restore(), login(), logout(), refreshTokens().")
    base.add_num(doc, "Настроить redirect в GoRouter (refreshListenable) и параметр from.")
    base.add_num(doc, "Скрывать кнопки создания по роли; дублировать проверку в redirect.")
    base.add_num(doc, "Добавить JWT и роли в api/mock-server.js, флаг --ttl для короткого access.")
    base.add_num(doc, "Перехватывать 401 в Dio, обновлять токен и повторять запрос.")
    base.add_num(doc, "Реализовать InactivityWatcher с выходом после 30 минут неактивности.")

    base.add_h1(doc, "3. Роли в предметной области")
    base.add_table(
        doc,
        ["Роль", "Права"],
        [
            ("viewer", "Только чтение списков оборудования и клиентов (GET)"),
            ("manager", "CRUD оборудования и клиентов; просмотр справочников"),
            ("admin", "Полный доступ, справочники, /admin/users"),
        ],
    )
    base.add_p(
        doc,
        "Учётные записи для демонстрации: admin/admin123, manager/manager123, "
        "viewer/viewer123 (пароли хранятся на сервере как SHA-256 с префиксом procat:).",
    )

    base.add_h1(doc, "4. AuthNotifier и хранение токенов")
    base.add_p(
        doc,
        "Класс lib/state/auth_notifier.dart хранит ключи auth_access_token и "
        "auth_refresh_token в SharedPreferences. При старте restore() вызывает "
        "GET /auth/me; при 401 пытается POST /auth/refresh. Метод has(Role) "
        "сравнивает уровень роли пользователя с требуемым.",
    )
    base.add_image(
        doc,
        CODE / "auth_notifier.dart.png",
        caption="Рисунок 1 — AuthNotifier: restore, login, refresh",
    )
    base.add_image(
        doc,
        UI / "01_login_redirect.png",
        caption="Рисунок 2 — Редирект неавторизованного пользователя на /login",
    )

    base.add_h1(doc, "5. GoRouter: redirect и защита маршрутов")
    base.add_p(
        doc,
        "Функция buildAppRouter принимает AuthNotifier и задаёт refreshListenable. "
        "Глобальный redirect направляет на /login?from=… при отсутствии сессии. "
        "Маршруты /equipment/new, /clients/new и справочники имеют локальный redirect "
        "на /forbidden при недостаточной роли.",
    )
    base.add_image(
        doc,
        CODE / "app_router_redirect.dart.png",
        caption="Рисунок 3 — Глобальный redirect и публичные маршруты",
    )

    base.add_h1(doc, "6. Скрытие действий в UI и экран 403")
    base.add_p(
        doc,
        "FloatingActionButton на списках показывается только при canEditRentals "
        "или canManageCatalog. Прямой переход по URL (например /admin/users под "
        "viewer) блокируется redirect — экран ForbiddenScreen с пояснением 403.",
    )
    base.add_image(
        doc,
        UI / "02_equipment_viewer.png",
        caption="Рисунок 4 — Вход под viewer: нет кнопки «+» на списке",
    )
    base.add_image(
        doc,
        UI / "03_forbidden_403.png",
        caption="Рисунок 5 — Страница /forbidden при доступе viewer к /admin/users",
    )
    base.add_image(
        doc,
        UI / "04_admin_users.png",
        caption="Рисунок 6 — Список пользователей для admin",
    )

    base.add_h1(doc, "7. JWT на mock API и проверка прав")
    base.add_p(
        doc,
        "В api/mock-server.js добавлены маршруты /auth/login, /auth/register, "
        "/auth/refresh, /auth/me и GET /admin/users. Все ресурсы ПР4 требуют "
        "заголовок Authorization: Bearer. Функция roleAllows запрещает POST/PUT/DELETE "
        "для viewer и ограничивает manager ресурсами equipment и clients.",
    )
    base.add_image(
        doc,
        CODE / "mock_server_auth.js.png",
        caption="Рисунок 7 — Выдача JWT и проверка роли на сервере",
    )

    base.add_h1(doc, "8. Обновление access-токена по 401")
    base.add_p(
        doc,
        "Interceptor _AuthRefreshInterceptor в api_client.dart при ответе 401 "
        "(кроме путей /auth/) вызывает auth.refreshTokens(), подставляет новый "
        "Bearer и повторяет запрос. Для демонстрации короткого TTL: "
        "node api/mock-server.js --ttl 60.",
    )
    base.add_image(
        doc,
        CODE / "api_client_refresh.dart.png",
        caption="Рисунок 8 — Повтор запроса после refresh",
    )
    base.add_image(
        doc,
        UI / "05_local_storage_tokens.png",
        caption="Рисунок 9 — Наличие ключей токенов в localStorage (DevTools)",
    )

    base.add_h1(doc, "9. Таймаут неактивности")
    base.add_p(
        doc,
        "Виджет InactivityWatcher оборачивает приложение при USE_API=true: "
        "сбрасывает таймер на клавиатуру и указатель мыши. По истечении "
        "inactivityLogoutDuration (30 минут, см. lib/core/config.dart) вызывается logout().",
    )
    base.add_image(
        doc,
        CODE / "inactivity_watcher.dart.png",
        caption="Рисунок 10 — InactivityWatcher",
    )

    base.add_h1(doc, "10. Тестирование и демонстрация")
    base.add_bullet(doc, "flutter test — модульные тесты API и сборка приложения (локальный режим);")
    base.add_bullet(doc, "scripts/run_api_server.ps1 и scripts/run_web.ps1 — совместный запуск;")
    base.add_bullet(doc, "Проверка: viewer не создаёт записи; manager не меняет справочники; admin видит пользователей;")
    base.add_bullet(doc, "Network: заголовок Authorization на GET /api/equipment после входа.")

    base.add_h1(doc, "11. Заключение")
    base.add_p(
        doc,
        "В работе № 5 приложение проката получило полноценный контур безопасности "
        "учебного уровня: JWT, роли, защита маршрутов и UI, автоматическое "
        "обновление access-токена и выход по неактивности. Сервер и клиент "
        "согласованы по кодам 401 и 403, что соответствует требованиям методички "
        "по аналогии со Spring Security.",
    )

    base.add_h1(doc, "Список основных файлов")
    base.add_bullet(doc, "lib/state/auth_notifier.dart, lib/api/auth_api.dart, lib/models/role.dart")
    base.add_bullet(doc, "lib/routing/app_router.dart, lib/screens/login_screen.dart, forbidden_screen.dart")
    base.add_bullet(doc, "lib/core/api_client.dart, lib/widgets/inactivity_watcher.dart")
    base.add_bullet(doc, "api/mock-server.js (auth, --ttl), api/db.json (users)")
    base.add_bullet(doc, "tools/generate_pr5_report.py, tools/capture_pr5_screenshots.py")


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
    base.add_h1(doc, "Практическая работа № 5. Авторизация и роли")
    build_content(doc)

    try:
        doc.save(OUT)
        print(OUT)
    except PermissionError:
        alt = ROOT / "Otchet_Praktika_5_Avtorizaciya_Roli.generated.docx"
        doc.save(alt)
        print(alt)


if __name__ == "__main__":
    main()
