# -*- coding: utf-8 -*-
"""Генерация полного отчёта по практической работе 2 в формате Word."""

from datetime import date
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Cm, Pt
from docx.oxml.ns import qn
from docx.oxml import OxmlElement


def set_document_defaults(doc: Document) -> None:
    style = doc.styles["Normal"]
    font = style.font
    font.name = "Times New Roman"
    font.size = Pt(14)
    style.paragraph_format.line_spacing = 1.5
    style.paragraph_format.space_after = Pt(0)
    # East Asia font for Cyrillic in Word
    rfonts = style.element.rPr.rFonts if style.element.rPr is not None else None
    if rfonts is None:
        rPr = style.element.get_or_add_rPr()
        rfonts = OxmlElement("w:rFonts")
        rPr.append(rfonts)
    rfonts.set(qn("w:ascii"), "Times New Roman")
    rfonts.set(qn("w:hAnsi"), "Times New Roman")
    rfonts.set(qn("w:cs"), "Times New Roman")


def add_heading(doc: Document, text: str, level: int = 1) -> None:
    h = doc.add_heading(text, level=level)
    for run in h.runs:
        run.font.name = "Times New Roman"
        run.font.color.rgb = None


def add_para(doc: Document, text: str, bold: bool = False, align=None) -> None:
    p = doc.add_paragraph()
    if align is not None:
        p.alignment = align
    run = p.add_run(text)
    run.font.name = "Times New Roman"
    run.font.size = Pt(14)
    run.bold = bold


def add_bullet(doc: Document, text: str) -> None:
    p = doc.add_paragraph(text, style="List Bullet")
    for run in p.runs:
        run.font.name = "Times New Roman"
        run.font.size = Pt(14)


def add_numbered(doc: Document, text: str) -> None:
    p = doc.add_paragraph(text, style="List Number")
    for run in p.runs:
        run.font.name = "Times New Roman"
        run.font.size = Pt(14)


def add_code_block(doc: Document, code: str) -> None:
    for line in code.strip().split("\n"):
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(1)
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(line if line else " ")
        run.font.name = "Consolas"
        run.font.size = Pt(10)


def add_table(doc: Document, headers: list[str], rows: list[list[str]]) -> None:
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = "Table Grid"
    hdr_cells = table.rows[0].cells
    for i, h in enumerate(headers):
        hdr_cells[i].text = h
        for p in hdr_cells[i].paragraphs:
            for run in p.runs:
                run.bold = True
                run.font.name = "Times New Roman"
                run.font.size = Pt(12)
    for r_idx, row in enumerate(rows):
        row_cells = table.rows[r_idx + 1].cells
        for c_idx, val in enumerate(row):
            row_cells[c_idx].text = val
            for p in row_cells[c_idx].paragraphs:
                for run in p.runs:
                    run.font.name = "Times New Roman"
                    run.font.size = Pt(12)
    doc.add_paragraph()


def build_report(output: Path) -> None:
    doc = Document()
    set_document_defaults(doc)

    # Титульный лист
    for _ in range(3):
        doc.add_paragraph()
    add_para(
        doc,
        "МИНИСТЕРСТВО НАУКИ И ВЫСШЕГО ОБРАЗОВАНИЯ РОССИЙСКОЙ ФЕДЕРАЦИИ",
        align=WD_ALIGN_PARAGRAPH.CENTER,
    )
    add_para(
        doc,
        "(наименование образовательной организации)",
        align=WD_ALIGN_PARAGRAPH.CENTER,
    )
    doc.add_paragraph()
    add_para(
        doc,
        "ОТЧЁТ\nпо практической работе № 2",
        bold=True,
        align=WD_ALIGN_PARAGRAPH.CENTER,
    )
    add_para(
        doc,
        "«Списки, поиск, фильтрация и пагинация»",
        bold=True,
        align=WD_ALIGN_PARAGRAPH.CENTER,
    )
    doc.add_paragraph()
    add_para(
        doc,
        "Тема итогового проекта:\n"
        "«Сервис проката туристического и мототехнического оборудования»",
        align=WD_ALIGN_PARAGRAPH.CENTER,
    )
    doc.add_paragraph()
    add_para(doc, "Выполнил(а): _________________________________", align=WD_ALIGN_PARAGRAPH.RIGHT)
    add_para(doc, "Группа: ______________________________________", align=WD_ALIGN_PARAGRAPH.RIGHT)
    add_para(doc, "Преподаватель: _______________________________", align=WD_ALIGN_PARAGRAPH.RIGHT)
    doc.add_paragraph()
    add_para(
        doc,
        f"2026",
        align=WD_ALIGN_PARAGRAPH.CENTER,
    )
    doc.add_page_break()

    # Содержание
    add_heading(doc, "Содержание", 1)
    toc_items = [
        "1. Введение",
        "2. Цель и задачи работы",
        "3. Используемые технологии",
        "4. Описание предметной области и сущностей",
        "5. Архитектура приложения",
        "6. Модели данных и объекты запросов",
        "7. Репозитории и работа с данными в памяти",
        "8. Управление состоянием (Provider)",
        "9. Пользовательский интерфейс",
        "10. Маршрутизация и параметры в URL",
        "11. Разбор ошибки в методе deleteMany",
        "12. Тестирование и проверка требований",
        "13. Примеры адресов с параметрами отбора",
        "14. Заключение",
        "Список использованных файлов проекта",
    ]
    for item in toc_items:
        add_para(doc, item)
    doc.add_page_break()

    # 1
    add_heading(doc, "1. Введение", 1)
    add_para(
        doc,
        "В рамках итогового учебного проекта разрабатывается веб-приложение на Flutter "
        "для сервиса проката туристического и мототехнического оборудования. "
        "Настоящая практическая работа посвящена построению каталогов двух сущностей — "
        "оборудования (Equipment) и клиентов (Client) — с полным набором операций просмотра, "
        "поиска, фильтрации, сортировки и постраничного вывода.",
    )
    add_para(
        doc,
        "На данном этапе серверный backend не подключается: все данные хранятся в оперативной "
        "памяти (in-memory) через репозитории-заглушки. Это позволяет сосредоточиться на "
        "архитектуре клиентской части, корректной работе списков и синхронизации состояния "
        "с адресной строкой браузера.",
    )

    # 2
    add_heading(doc, "2. Цель и задачи работы", 1)
    add_para(doc, "Цель работы — реализовать два каталога с единообразным поведением списков и подготовить основу для последующего подключения API.",)
    add_para(doc, "Задачи:", bold=True)
    add_numbered(doc, "Спроектировать слоистую структуру проекта (models, repositories, state, screens, widgets).")
    add_numbered(doc, "Реализовать immutable-модели с copyWith и поддержкой логического удаления (deletedAt).")
    add_numbered(doc, "Ввести обобщённый тип PageResult<T> для постраничной выдачи.")
    add_numbered(doc, "Реализовать объекты запросов EquipmentQuery и ClientQuery с сбросом номера страницы при смене условий отбора.")
    add_numbered(doc, "Создать in-memory репозитории с задержкой загрузки, поиском, фильтрами, сортировкой и пагинацией.")
    add_numbered(doc, "Организовать состояние экранов через ChangeNotifier и пакет provider.")
    add_numbered(doc, "Построить UI: таблица/карточки, четыре различимых состояния экрана, debounce-поиск, пагинация.")
    add_numbered(doc, "Синхронизировать условия отбора с query-параметрами URL (go_router).")
    add_numbered(doc, "Реализовать логическое и физическое удаление, восстановление и массовое удаление.")
    add_numbered(doc, "Найти и исправить преднамеренную ошибку в deleteMany (по заданию практики).")

    # 3
    add_heading(doc, "3. Используемые технологии", 1)
    add_bullet(doc, "Flutter (целевая платформа — Web);")
    add_bullet(doc, "Dart 3.x;")
    add_bullet(doc, "Управление состоянием: provider (ChangeNotifierProvider, context.watch / context.read);")
    add_bullet(doc, "Маршрутизация: go_router с usePathUrlStrategy() для «чистых» URL без #;")
    add_bullet(doc, "Статический анализ: flutter analyze (в проекте — без замечаний);")
    add_bullet(doc, "Сборка: flutter build web / запуск flutter run -d chrome.")

    # 4
    add_heading(doc, "4. Описание предметной области и сущностей", 1)
    add_heading(doc, "4.1. Equipment (оборудование)", 2)
    add_para(
        doc,
        "Единица инвентаря, сдаваемая в прокат. Поля: id, name, inventoryNumber (уникальный), "
        "categoryId, brandId, purchaseYear, dailyRate, condition («новое» | «хорошее» | «требует обслуживания»), "
        "unitsTotal, unitsAvailable, tagIds, deletedAt (для soft delete).",
    )
    add_para(doc, "Справочники в памяти:", bold=True)
    add_bullet(doc, "Категории: Палатки, Велосипеды, Мотоциклы, Квадроциклы, Водный транспорт, Снегоходы;")
    add_bullet(doc, "Бренды: Tramp, Stels, Yamaha, Polaris, Trek, Sea-Doo, Buran;")
    add_bullet(doc, "Теги: зима, лето, для новичков, экстрим, водный.")
    add_para(doc, "В seed-данных репозитория — 22 единицы оборудования с реалистичными названиями.")

    add_heading(doc, "4.2. Client (клиент)", 2)
    add_para(
        doc,
        "Поля: id, fullName, phone, city, registeredAt, deletedAt. "
        "В начальных данных — 9 клиентов из городов Урала и Сибири.",
    )

    # 5
    add_heading(doc, "5. Архитектура приложения", 1)
    add_para(
        doc,
        "Приложение разделено на слои. Экраны и виджеты не обращаются к репозиториям напрямую — "
        "только через классы EquipmentListNotifier и ClientListNotifier.",
    )
    add_table(
        doc,
        ["Слой", "Каталог", "Назначение"],
        [
            ["Модели", "lib/models/", "Сущности, PageResult, Query, справочники, LoadStatus"],
            ["Репозитории", "lib/repositories/", "Интерфейсы и InMemory* реализации"],
            ["Состояние", "lib/state/", "ChangeNotifier для списков и карточек"],
            ["Экраны", "lib/screens/", "Списки и детальный просмотр"],
            ["Виджеты", "lib/widgets/", "EntityTable, пагинация, поиск, заглушки состояний"],
            ["Маршруты", "lib/routing/", "Парсинг и сериализация query-параметров"],
        ],
    )
    add_para(
        doc,
        "Схема потока данных: экран вызывает метод notifier (например applyQuery) → "
        "notifier обращается к репозиторию → результат сохраняется в PageResult → "
        "notifyListeners() → UI перестраивается через Provider.",
    )
    add_para(
        doc,
        "[Место для рисунка: схема слоёв приложения — models / repositories / state / screens / widgets]",
    )

    # 6
    add_heading(doc, "6. Модели данных и объекты запросов", 1)
    add_para(
        doc,
        "Классы Equipment и Client — неизменяемые (immutable), с конструктором и copyWith. "
        "Для поля deletedAt добавлен флаг clearDeletedAt, чтобы отличать «не менять» от «установить null».",
    )
    add_para(doc, "PageResult<T> содержит items, page, size, total; геттеры totalPages (при 0 записях — 1 страница), hasPrevious, hasNext; конструктор PageResult.empty() для начального состояния.",)
    add_para(
        doc,
        "EquipmentQuery и ClientQuery — неизменяемые объекты со всеми условиями отбора. "
        "Для nullable-полей фильтров в copyWith используется сигнальная константа _unset = Object(), "
        "чтобы различать «параметр не передан» и «передан null для сброса фильтра». "
        "При изменении любого условия отбора (кроме явной смены page) номер страницы сбрасывается на 1.",
    )
    add_para(doc, "Фильтры оборудования (комбинируются одновременно):", bold=True)
    add_bullet(doc, "categoryId — категория;")
    add_bullet(doc, "brandId — бренд;")
    add_bullet(doc, "dailyRateFrom / dailyRateTo — диапазон суточного тарифа;")
    add_bullet(doc, "yearFrom / yearTo — диапазон года покупки;")
    add_bullet(doc, "includeDeleted — показ логически удалённых записей.")

    # 7
    add_heading(doc, "7. Репозитории и работа с данными в памяти", 1)
    add_para(
        doc,
        "Интерфейсы EquipmentRepository и ClientRepository определяют методы: find, findById, create, "
        "update, softDelete, hardDelete, restore, deleteMany.",
    )
    add_para(doc, "Метод find() в in-memory реализации:", bold=True)
    add_numbered(doc, "Искусственная задержка ~250 мс (имитация сети, виден индикатор загрузки).")
    add_numbered(doc, "Фильтр includeDeleted / скрытие записей с deletedAt.")
    add_numbered(doc, "Поиск: Equipment — по name и inventoryNumber; Client — по fullName и phone.")
    add_numbered(doc, "Применение фильтров (для оборудования — минимум три независимых критерия).")
    add_numbered(doc, "Сортировка по настраиваемому полю и направлению (не менее трёх полей на сущность).")
    add_numbered(doc, "Пагинация через sublist; верхняя граница to вычисляется как int (без num.clamp).")
    add_para(
        doc,
        "Сортировка Equipment: name, dailyRate, purchaseYear, inventoryNumber. "
        "Сортировка Client: fullName, phone, city, registeredAt.",
    )

    # 8
    add_heading(doc, "8. Управление состоянием (Provider)", 1)
    add_para(
        doc,
        "EquipmentListNotifier и ClientListNotifier содержат: query, result (PageResult), "
        "status (LoadStatus: idle, loading, success, error), error, selected (Set<int>), "
        "а также поля для детального экрана (detailItem, detailStatus).",
    )
    add_para(doc, "Ключевые методы: load(), applyQuery(next), toggleSelection(id), deleteSelected(), hardDeleteSelected(), restoreSelected(), restore(id), softDelete / hardDelete для одной записи.",)
    add_para(
        doc,
        "В load() вызывается notifyListeners() в начале (статус loading) и в конце (success или error). "
        "applyQuery очищает selected. Переключатель «Показать удалённые» меняет includeDeleted в query.",
    )
    add_para(
        doc,
        "setState используется только для локального UI (раскрытие панели фильтров на экране оборудования), "
        "не для данных списка.",
    )

    # 9
    add_heading(doc, "9. Пользовательский интерфейс", 1)
    add_heading(doc, "9.1. Обобщённая таблица EntityTable<T>", 2)
    add_para(
        doc,
        "Виджет lib/widgets/entity_table.dart принимает список TableColumnSpec<T> (label, sortField, numeric, build), "
        "данные, idOf, выделение, параметры сортировки и колбэки. Одна реализация используется "
        "для оборудования и клиентов без дублирования кода. Таблица обёрнута в двойную прокрутку "
        "(горизонтальная + вертикальная), чтобы на узких экранах содержимое не выходило за границы окна.",
    )
    add_heading(doc, "9.2. Адаптивная вёрстка", 2)
    add_para(
        doc,
        "При ширине окна менее 600 px вместо таблицы отображается ListView с Card для каждой записи "
        "(те же действия: выделение, открытие карточки, удаление). При ширине 600 px и более — DataTable.",
    )
    add_heading(doc, "9.3. Состояния экрана", 2)
    add_table(
        doc,
        ["Состояние", "Отображение"],
        [
            ["loading", "CircularProgressIndicator по центру"],
            ["success (есть данные)", "Таблица или список карточек"],
            ["success (пусто)", "ListEmptyView — иконка и текст «Ничего не найдено…»"],
            ["error", "ListErrorView — иконка ошибки, текст, кнопка «Повторить»"],
        ],
    )
    add_heading(doc, "9.4. Поиск, фильтры, пагинация", 2)
    add_bullet(doc, "DebouncedSearchField — задержка 350 мс после ввода;")
    add_bullet(doc, "Сортировка по клику на заголовок колонки со стрелкой направления;")
    add_bullet(doc, "Пагинация: размер страницы 10 / 25 / 50, кнопки первая / пред / след / последняя, отображение page и total.")
    add_heading(doc, "9.5. Экраны", 2)
    add_bullet(doc, "/equipment — список оборудования;")
    add_bullet(doc, "/equipment/:id — карточка со всеми полями;")
    add_bullet(doc, "/clients — список клиентов;")
    add_bullet(doc, "/clients/:id — карточка клиента.")
    add_para(doc, "[Место для скриншотов: список оборудования, пустой результат, ошибка, мобильные карточки, карточка детали]",)

    # 10
    add_heading(doc, "10. Маршрутизация и параметры в URL", 1)
    add_para(
        doc,
        "В main.dart настроен GoRouter. Все условия отбора кодируются в query-параметрах, например: "
        "/equipment?search=палатка&categoryId=1&sort=dailyRate,desc&page=1&size=10.",
    )
    add_para(
        doc,
        "При открытии URL в новой вкладке экран в didChangeDependencies парсит параметры "
        "(lib/routing/query_params.dart) и вызывает applyQuery. При изменении query в notifier "
        "адрес обновляется через context.go в SchedulerBinding.instance.addPostFrameCallback, "
        "чтобы избежать циклических пересборок. Кнопка «Назад» браузера восстанавливает предыдущий набор условий.",
    )

    # 11
    add_heading(doc, "11. Разбор ошибки в методе deleteMany", 1)
    add_para(
        doc,
        "По заданию практики сначала была реализована версия с ошибкой (закомментирована в файле "
        "in_memory_equipment_repository.dart с пометкой «ВАРИАНТ С ОШИБКОЙ»), затем исправлена.",
    )
    add_para(doc, "Было:", bold=True)
    add_code_block(
        doc,
        """
final index = _items.indexWhere((e) => e.id == ids[i]);
if (index > 0) {
  _items.removeAt(index);
  removed++;
}
""",
    )
    add_para(doc, "Стало:", bold=True)
    add_code_block(
        doc,
        """
final index = _items.indexWhere((e) => e.id == id);
if (index >= 0) {
  _items.removeAt(index);
  removed++;
}
""",
    )
    add_para(
        doc,
        "Ошибка: условие index > 0 отбрасывает элемент с индексом 0. Если удаляемая запись "
        "находилась в начале внутреннего списка _items, она не удалялась, хотя её id был передан в deleteMany. "
        "Проявление: при массовом удалении, включая «первую» запись в списке, счётчик удалённых был занижен. "
        "Исправление: проверять index >= 0, как принято после indexWhere, когда -1 означает «не найдено».",
    )

    # 12
    add_heading(doc, "12. Тестирование и проверка требований", 1)
    add_para(doc, "Выполненные проверки:", bold=True)
    add_bullet(doc, "flutter analyze — замечаний нет;")
    add_bullet(doc, "flutter build web — сборка успешна;")
    add_bullet(doc, "Ручная проверка: смена фильтра сбрасывает страницу на 1;")
    add_bullet(doc, "Ручная проверка: копирование URL с параметрами восстанавливает состояние списка;")
    add_bullet(doc, "Ручная проверка: soft delete скрывает запись; includeDeleted показывает; restore снимает deletedAt;")
    add_bullet(doc, "Ручная проверка: hard delete только после подтверждения в AlertDialog.")
    add_table(
        doc,
        ["Типичная ошибка (методичка)", "Как избежано в проекте"],
        [
            ["Не вызван notifyListeners", "В load() — в начале и в конце"],
            ["Страница не сбрасывается при фильтре", "copyWith в Query-объектах"],
            ["Пустой результат как загрузка", "Отдельный ListEmptyView"],
            ["Таблица уезжает за край", "Двойной ScrollView в EntityTable"],
            ["Выделение не сбрасывается", "selected.clear() в applyQuery"],
            ["Поиск без debounce", "DebouncedSearchField 350 мс"],
            ["Provider не найден", "MultiProvider в main.dart"],
        ],
    )
    add_para(doc, "Команды запуска:", bold=True)
    add_code_block(
        doc,
        """
cd procatMotoTurizm
flutter pub get
flutter run -d chrome
""",
    )

    # 13
    add_heading(doc, "13. Примеры адресов с параметрами отбора", 1)
    add_para(doc, "Базовый хост при локальном запуске: http://localhost:<порт>.",)
    add_para(doc, "Оборудование:", bold=True)
    add_bullet(doc, "/equipment?search=палатка&categoryId=1&sort=dailyRate,desc&page=1&size=10")
    add_bullet(doc, "/equipment?categoryId=4&brandId=2&dailyRateFrom=3000&dailyRateTo=5000&sort=name,asc&page=1&size=25")
    add_bullet(doc, "/equipment?categoryId=3&yearFrom=2020&sort=purchaseYear,desc&page=1&size=10")
    add_bullet(doc, "/equipment?includeDeleted=true&sort=name,asc&page=1&size=10")
    add_para(doc, "Клиенты:", bold=True)
    add_bullet(doc, "/clients?search=Иванов&city=Екатеринбург&sort=fullName,asc&page=1&size=10")
    add_bullet(doc, "/clients?sort=registeredAt,desc&page=1&size=25")
    add_bullet(doc, "/clients?includeDeleted=true&sort=fullName,asc&page=1&size=10")

    # 14
    add_heading(doc, "14. Заключение", 1)
    add_para(
        doc,
        "В ходе практической работы № 2 разработано Flutter Web-приложение каталога проката "
        "с двумя сущностями, in-memory репозиториями и полным циклом работы со списками: "
        "поиск, фильтрация, сортировка, пагинация, логическое и физическое удаление, "
        "синхронизация состояния с URL. Соблюдена слоистая архитектура и управление "
        "состоянием через provider. Обобщённый виджет таблицы упрощает расширение проекта "
        "новыми сущностями. Исправлена учебная ошибка в deleteMany. Проект готов к этапу "
        "подключения реального backend API без переработки экранов — достаточно заменить "
        "реализации репозиториев.",
    )

    add_heading(doc, "Список основных файлов проекта", 1)
    files = [
        "lib/main.dart",
        "lib/models/* (equipment, client, queries, page_result, catalog_data, load_status)",
        "lib/repositories/* (интерфейсы и in_memory_*)",
        "lib/state/equipment_list_notifier.dart, client_list_notifier.dart",
        "lib/routing/query_params.dart",
        "lib/screens/* (4 экрана)",
        "lib/widgets/* (entity_table, pagination, search, состояния, диалоги)",
        "REPORT_NOTES.md — краткий черновик для отчёта",
    ]
    for f in files:
        add_bullet(doc, f)

    doc.save(output)
    print(f"Saved: {output}")


if __name__ == "__main__":
    out = Path(__file__).resolve().parents[1] / "Отчет_Практика_2_Списки_и_пагинация.docx"
    build_report(out)
