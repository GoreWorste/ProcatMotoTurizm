# Черновик отчёта — практика «Списки, поиск, фильтрация и пагинация»

## 1. Схема слоёв приложения

| Слой | Путь | Назначение |
|------|------|------------|
| **models** | `lib/models/` | Неизменяемые сущности (`Equipment`, `Client`), запросы (`EquipmentQuery`, `ClientQuery`), `PageResult<T>`, справочники |
| **repositories** | `lib/repositories/` | Абстракции доступа к данным и in-memory реализации с задержкой и бизнес-логикой выборки |
| **state** | `lib/state/` | `ChangeNotifier` для списков: загрузка, query, выделение, удаление |
| **screens** | `lib/screens/` | Экраны списков и карточек; работают только с notifier через Provider |
| **widgets** | `lib/widgets/` | Переиспользуемые UI-компоненты (`EntityTable`, пагинация, debounce-поиск, состояния loading/empty/error) |
| **routing** | `lib/routing/` | Парсинг и сериализация query-параметров URL |

Виджеты и экраны **не** импортируют репозитории напрямую — только `EquipmentListNotifier` / `ClientListNotifier`.

## 2. Зачем обобщённый `EntityTable<T>`

Таблица описывается массивом `TableColumnSpec<T>` (заголовок, поле сортировки, ячейка). Один виджет обслуживает оборудование и клиентов: не дублируется разметка `DataTable`, чекбоксы, прокрутка по двум осям и обработка сортировки. При добавлении новой сущности достаточно задать колонки и передать данные.

## 3. Ошибка в `deleteMany` (шаг А / Б)

**Было (вариант с ошибкой, закомментирован в репозитории):**

```dart
final index = _items.indexWhere((e) => e.id == ids[i]);
if (index > 0) {
  _items.removeAt(index);
  removed++;
}
```

**Стало:**

```dart
final index = _items.indexWhere((e) => e.id == id);
if (index >= 0) {
  _items.removeAt(index);
  removed++;
}
```

**Суть ошибки:** условие `index > 0` отбрасывает элемент с индексом `0` в списке. Если нужная запись была первой в `_items`, она не удалялась при массовом удалении, хотя id был в списке на удаление.

**Как проявлялась:** при выборе нескольких записей, включая ту, что хранится в начале списка, счётчик удалённых был меньше ожидаемого; «первая» запись оставалась в каталоге.

**Как нашли:** сравнение с типовой ошибкой из методички (неверная проверка индекса после `indexWhere`), ручной прогон `deleteMany` для id первого элемента.

## 4. Примеры URL с параметрами

Базовый адрес при локальном запуске: `http://localhost:<port>`.

**Оборудование:**

- Поиск палаток, категория «Палатки» (id=1), сортировка по тарифу по убыванию, страница 1:  
  `/equipment?search=палатка&categoryId=1&sort=dailyRate,desc&page=1&size=10`
- Квадроциклы Stels, тариф 3000–5000 ₽:  
  `/equipment?categoryId=4&brandId=2&dailyRateFrom=3000&dailyRateTo=5000&sort=name,asc&page=1&size=25`
- Мотоциклы, год выпуска с 2020:  
  `/equipment?categoryId=3&yearFrom=2020&sort=purchaseYear,desc&page=1&size=10`
- Показать удалённые:  
  `/equipment?includeDeleted=true&sort=name,asc&page=1&size=10`

**Клиенты:**

- Поиск по имени, город Екатеринбург:  
  `/clients?search=Иванов&city=Екатеринбург&sort=fullName,asc&page=1&size=10`
- Сортировка по дате регистрации:  
  `/clients?sort=registeredAt,desc&page=1&size=25`
- Удалённые клиенты:  
  `/clients?includeDeleted=true&sort=fullName,asc&page=1&size=10`

## 5. Чек-лист типичных ошибок

| Ошибка | Как избежано |
|--------|----------------|
| Не вызван `notifyListeners` | В `load()` — в начале (loading) и в конце (success/error) |
| Страница не сбрасывается при смене фильтра | `EquipmentQuery.copyWith` / `ClientQuery.copyWith` сбрасывают `page` на 1 при изменении любого условия, кроме явной передачи `page` |
| Индикатор загрузки не пропадает | `LoadStatus` переводится в `success` или `error` после `await find()` |
| Пустой результат показан как загрузка | Отдельный `ListEmptyView` при `success` и `items.isEmpty` |
| Provider не найден | `MultiProvider` в `main.dart` с репозиториями и notifier |
| Таблица уезжает за край | `EntityTable` — вложенные `SingleChildScrollView` по горизонтали и вертикали |
| Выделение не очищается при смене фильтра | `applyQuery` вызывает `selected.clear()` |
| Поиск без debounce | `DebouncedSearchField` с таймером 350 мс |
| `setState` для данных списка | Данные только в `ChangeNotifier`; `setState` — только для раскрытия панели фильтров |
| URL не синхронизирован с query | Парсинг в `didChangeDependencies`, обновление через `context.go` в `addPostFrameCallback` |

## Запуск

```bash
flutter pub get
flutter run -d chrome
```

`flutter analyze` — без замечаний.
