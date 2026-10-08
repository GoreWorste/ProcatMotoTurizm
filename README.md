# Прокат мототехники (Flutter Web)

Учебный проект: ПР2 (списки, поиск, фильтры, пагинация) + ПР3 (формы, валидация, связи, `shared_preferences`).

## Запуск

```bash
flutter pub get
```

**Запуск в браузере** (обязательно с локальными ресурсами, иначе при блокировке `gstatic.com` / `fonts.gstatic.com` будет белый экран и ошибки CanvasKit/Roboto):

```powershell
.\scripts\run_web.ps1
```

или:

```bash
flutter run -d chrome --web-port=5555 --no-web-resources-cdn
```

Сообщения `RemoteDebuggerExecutionContext` / `dartDevEmbedder` в консоли IDE при старте — шум отладчика, на работу приложения не влияют, если CanvasKit загрузился.

Данные сохраняются в `localStorage` (ключи `equipment_v1`, `clients_v1`, `categories_v1`, `brands_v1`, `tags_v1`).

## Соответствие сущностей ПР3

| Учебная модель | Проект | Связи |
|----------------|--------|--------|
| Book | Equipment | M2O Category, M2O Brand, M2M Tag |
| Author | Tag | M2M Equipment |
| Genre | Category | через Equipment |
| Publisher | Brand | M2O Equipment, защита удаления |
| Reader + билет | Client + RentalCard | O2O вложенные поля |

## Отчёт: схемы и валидация

**Логическая схема:** Client 1—1 RentalCard; Equipment N—1 Category; Equipment N—1 Brand; Equipment N—M Tag.

**Физическое хранилище (web):** JSON-массивы в `shared_preferences` / localStorage, отдельный ключ `meta_v1` для счётчиков id.

### Словарь данных (основные поля)

| Сущность | Поля |
|----------|------|
| Equipment | id, name, inventoryNumber, categoryId, brandId, purchaseYear, dailyRate, condition, unitsTotal, unitsAvailable, tagIds, deletedAt |
| Client | id, fullName, email, phone, city, registeredAt, rentalCard{number, issuedAt}, deletedAt |
| Category / Brand / Tag | id, name, deletedAt |

### Проверки полей (кратко)

| Поле | Проверки |
|------|----------|
| Название оборудования | обязательно, длина 2–200 |
| Инвентарный номер | формат EQ-…, уникальность |
| Категория / бренд | обязательный выбор; бренды фильтруются по категории |
| Теги | минимум один |
| Год покупки | целое, диапазон |
| Тариф, количества | число > 0, доступно ≤ всего |
| ФИО клиента | обязательно, длина |
| Email | формат, уникальность |
| Телефон | формат РФ |
| Город | обязательный выбор |
| Билет | номер, дата |
| Справочники (имя) | обязательно, длина 2–80 |

Общие валидаторы: `lib/core/validators.dart`. Общая обёртка формы: `lib/widgets/form_scaffold.dart`, декларативные текстовые поля: `lib/widgets/declarative_form_fields.dart`.

## Отчёт ПР3 (DOCX)

После `flutter build web --no-web-resources-cdn`:

```powershell
.\tools\build_pr3_report.ps1
```

Результат: **`Otchet_Praktika_3_Formy_i_validaciya.docx`** в корне проекта.  
Снимки: `screenshots_report/pr3/ui/`, фрагменты кода: `screenshots_report/pr3/code/`.  
Репозиторий: [GoreWorste/ProcatMotoTurizm](https://github.com/GoreWorste/ProcatMotoTurizm/tree/dev).

## Практическая работа 4 (REST API)

1. Экспорт seed (при изменении данных): `dart run tools/export_api_seed.dart`
2. Сервер: `.\scripts\run_api_server.ps1` (или `node api/mock-server.js --port 8080 --origin http://localhost:5555`)
3. Проверка: http://localhost:8080/api/__health
4. Клиент (порт **5555** для CORS): `.\scripts\run_web.ps1`
5. Другой хост API: `--dart-define=API_BASE_URL=http://192.168.1.10:8080/api`
6. Локальный режим ПР3 без сервера: `--dart-define=USE_API=false`
7. Тесты репозитория: `flutter test test/api_equipment_repository_test.dart`
8. Отчёт: `python tools\generate_pr4_report.py` → `Otchet_Praktika_4_REST_API.docx`

Контракт: `api/КОНТРАКТ-API.md`.

## Практическая работа 5 (авторизация и роли)

1. Запустите API и клиент (`run_api_server.ps1`, `run_web.ps1`).
2. Учётные записи: `admin` / `admin123`, `manager` / `manager123`, `viewer` / `viewer123`.
3. Токены в DevTools → Application → Local storage → `flutter.auth_access_token`, `flutter.auth_refresh_token`.
4. Короткий TTL access: `.\scripts\run_api_server_ttl.ps1` (`--ttl 60`).
5. Отчёт: `python tools\generate_pr5_report.py` → `Otchet_Praktika_5_Avtorizaciya_Roli.docx`.

## Практическая работа 6 (адаптив, сборка, публикация)

**Точки перелома:** 360 / 768 / 1280 / 1920 px — `lib/core/layout_breakpoints.dart`.

**Production-сборка (поддомен, `base-href /`):**

```powershell
.\scripts\build_production.ps1
```

**Публикация на VPS** (`motoprocatflutter.romanovivv.ru` → A-запись на IP сервера):

```powershell
.\scripts\deploy_to_vps.ps1 -User root -Host 213.171.28.69
```

На сервере: nginx по примеру `deploy/nginx-motoprocatflutter.conf`, каталог `/var/www/motoprocatflutter`.

**Отчёт ПР6:** `python tools\generate_pr6_report.py` → `Otchet_Praktika_6_Adaptiv_Sborka_Publikaciya.docx`

Для API+авторизации (ПР4–ПР5) — локально `run_api_server.ps1` + `run_web.ps1`.
