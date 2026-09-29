# Прокат мототехники (Flutter Web)

Учебный проект: ПР2 (списки, поиск, фильтры, пагинация) + ПР3 (формы, валидация, связи, `shared_preferences`).

## Запуск

```bash
flutter pub get
flutter run -d chrome --web-port=5555
```

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
