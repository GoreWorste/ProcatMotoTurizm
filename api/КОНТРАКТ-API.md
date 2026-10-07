# Контракт учебного API (прокат мототехники)

Базовый URL: `http://localhost:8080/api` (задаётся через `--dart-define=API_BASE_URL=...`).

## Служебные

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/__health` | Проверка доступности сервера |
| * | `?__delay=1500` | Искусственная задержка ответа (мс) |
| * | `?__fail=500` | Учебная ошибка с указанным HTTP-кодом |

## Оборудование (`/equipment`)

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/equipment` | Список с `search`, `categoryId`, `brandId`, `dailyRateFrom/To`, `yearFrom/To`, `sort`, `page`, `size`, `includeDeleted` |
| GET | `/equipment/:id` | Одна запись |
| POST | `/equipment` | Создание (тело — поля без `id`) |
| PUT | `/equipment/:id` | Обновление |
| DELETE | `/equipment/:id` | Мягкое удаление |
| DELETE | `/equipment/:id?hard=true` | Физическое удаление |
| POST | `/equipment/:id/restore` | Восстановление |
| POST | `/equipment/bulk-delete` | `{ "ids": [1,2] }` → `{ "deleted": n }` |
| GET | `/equipment/meta/brand-ids?categoryId=` | ID брендов для категории |

**422:** дубликат `inventoryNumber` → `errors.inventoryNumber`.

## Клиенты (`/clients`)

Аналогично: `GET/POST/PUT/DELETE`, `bulk-delete`, `restore`.  
**422:** дубликат `email` → `errors.email`.

## Справочники (`/categories`, `/brands`, `/tags`)

CRUD + `bulk-delete`, `restore`.  
**409:** `DELETE ?hard=true` при связанном оборудовании (бренд/категория).

## Формат страницы

```json
{ "items": [], "page": 1, "size": 10, "total": 0 }
```

## Ошибки

| Код | Тело |
|-----|------|
| 422 | `{ "message": "...", "errors": { "field": "текст" } }` |
| 409 | `{ "message": "..." }` |
| 404 | `{ "message": "Запись не найдена" }` |

Ключи в `errors` совпадают с именами полей формы Flutter.
