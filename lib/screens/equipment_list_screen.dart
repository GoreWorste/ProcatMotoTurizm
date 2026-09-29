import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/catalog_notifier.dart';
import '../models/equipment.dart';
import '../models/equipment_query.dart';
import '../models/load_status.dart';
import '../routing/query_params.dart';
import '../state/equipment_list_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_views.dart';
import '../widgets/pagination_bar.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  bool _filtersExpanded = true;
  String? _appliedUri;
  bool _skipUriApply = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_skipUriApply) return;

    final uriString = GoRouterState.of(context).uri.toString();
    if (_appliedUri == uriString) return;
    _appliedUri = uriString;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _skipUriApply) return;

      final parsed =
          equipmentQueryFromUri(GoRouterState.of(context).uri.queryParameters);
      final notifier = context.read<EquipmentListNotifier>();
      if (!_queriesEqual(parsed, notifier.query)) {
        notifier.applyQuery(parsed);
      } else if (notifier.status == LoadStatus.idle) {
        notifier.load();
      }
    });
  }

  bool _queriesEqual(EquipmentQuery a, EquipmentQuery b) {
    return equipmentQueryToParams(a).toString() ==
        equipmentQueryToParams(b).toString();
  }

  Future<void> _apply(EquipmentQuery next) async {
    _skipUriApply = true;
    final notifier = context.read<EquipmentListNotifier>();
    await notifier.applyQuery(next);
    final uri = Uri(
      path: '/equipment',
      queryParameters: equipmentQueryToParams(notifier.query),
    );
    _appliedUri = uri.toString();
    if (mounted && GoRouterState.of(context).uri.toString() != _appliedUri) {
      context.go(_appliedUri!);
    }
    _skipUriApply = false;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EquipmentListNotifier>();
    final catalog = context.watch<CatalogNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Оборудование')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/equipment/new'),
        tooltip: 'Добавить',
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DebouncedSearchField(
                  initialValue: notifier.query.search,
                  hintText: 'Поиск по названию или инв. номеру',
                  onChanged: (value) =>
                      _apply(notifier.query.copyWith(search: value)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Показать удалённые'),
                      selected: notifier.showDeleted,
                      onSelected: (value) => _apply(
                        notifier.query.copyWith(includeDeleted: value),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: _filtersExpanded
                          ? 'Свернуть фильтры'
                          : 'Развернуть фильтры',
                      onPressed: () => setState(
                        () => _filtersExpanded = !_filtersExpanded,
                      ),
                      icon: Icon(
                        _filtersExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                    ),
                  ],
                ),
                if (_filtersExpanded)
                  _EquipmentFilters(
                    query: notifier.query,
                    catalog: catalog,
                    onApply: _apply,
                  ),
                _SelectionBar(notifier: notifier),
              ],
            ),
          ),
          Expanded(child: _buildBody(notifier, catalog)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: PaginationBar(
              result: notifier.result,
              onPageChanged: (page) =>
                  _apply(notifier.query.copyWith(page: page)),
              onSizeChanged: (size) =>
                  _apply(notifier.query.copyWith(size: size)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(EquipmentListNotifier notifier, CatalogNotifier catalog) {
    switch (notifier.status) {
      case LoadStatus.loading:
      case LoadStatus.idle:
        return const ListLoadingView();
      case LoadStatus.error:
        return ListErrorView(
          message: notifier.error ?? 'Ошибка загрузки',
          onRetry: () => notifier.load(),
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const ListEmptyView();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final useCards = constraints.maxWidth < 600;
            if (useCards) {
              return _EquipmentCardList(
                catalog: catalog,
                items: notifier.result.items,
                selected: notifier.selected,
                onToggle: notifier.toggleSelection,
                onOpen: (id) => context.go('/equipment/$id'),
                onSoftDelete: _confirmSoftDelete,
                onHardDelete: _confirmHardDelete,
                onRestore: (id) => notifier.restore(id),
              );
            }
            return EntityTable<Equipment>(
              columns: _columns(catalog),
              items: notifier.result.items,
              idOf: (e) => e.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              sortField: notifier.query.sortField,
              sortAscending: notifier.query.sortAscending,
              onSort: (field) {
                final ascending = notifier.query.sortField == field
                    ? !notifier.query.sortAscending
                    : true;
                _apply(notifier.query.withSort(field, ascending));
              },
              actions: (item) => _rowActions(item, notifier),
            );
          },
        );
    }
  }

  List<TableColumnSpec<Equipment>> _columns(CatalogNotifier catalog) => [
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (e) => Text(e.name),
        ),
        TableColumnSpec(
          label: 'Инв. №',
          sortField: 'inventoryNumber',
          build: (e) => Text(e.inventoryNumber),
        ),
        TableColumnSpec(
          label: 'Категория',
          sortField: 'name',
          build: (e) => Text(catalog.categoryName(e.categoryId)),
        ),
        TableColumnSpec(
          label: 'Тариф/сут.',
          sortField: 'dailyRate',
          numeric: true,
          build: (e) => Text('${e.dailyRate.toStringAsFixed(0)} ₽'),
        ),
        TableColumnSpec(
          label: 'Год',
          sortField: 'purchaseYear',
          numeric: true,
          build: (e) => Text('${e.purchaseYear}'),
        ),
      ];

  Widget _rowActions(Equipment item, EquipmentListNotifier notifier) {
    return Wrap(
      spacing: 4,
      children: [
        IconButton(
          tooltip: 'Открыть',
          icon: const Icon(Icons.open_in_new),
          onPressed: () => context.go('/equipment/${item.id}'),
        ),
        if (item.deletedAt == null)
          IconButton(
            tooltip: 'Удалить',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmSoftDelete(item.id),
          )
        else ...[
          IconButton(
            tooltip: 'Восстановить',
            icon: const Icon(Icons.restore),
            onPressed: () => notifier.restore(item.id),
          ),
          IconButton(
            tooltip: 'Удалить навсегда',
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _confirmHardDelete(item.id),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmSoftDelete(int id) async {
    final ok = await confirmAction(
      context,
      title: 'Логическое удаление',
      message: 'Пометить запись как удалённую?',
      confirmLabel: 'Удалить',
    );
    if (!ok || !mounted) return;
    await context.read<EquipmentListNotifier>().softDelete(id);
  }

  Future<void> _confirmHardDelete(int id) async {
    final ok = await confirmAction(
      context,
      title: 'Физическое удаление',
      message: 'Запись будет удалена без возможности восстановления.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    await context.read<EquipmentListNotifier>().hardDelete(id);
  }
}

class _EquipmentFilters extends StatefulWidget {
  const _EquipmentFilters({
    required this.query,
    required this.catalog,
    required this.onApply,
  });

  final EquipmentQuery query;
  final CatalogNotifier catalog;
  final Future<void> Function(EquipmentQuery) onApply;

  @override
  State<_EquipmentFilters> createState() => _EquipmentFiltersState();
}

class _EquipmentFiltersState extends State<_EquipmentFilters> {
  Timer? _debounce;
  late final TextEditingController _rateFrom;
  late final TextEditingController _rateTo;
  late final TextEditingController _yearFrom;
  late final TextEditingController _yearTo;

  @override
  void initState() {
    super.initState();
    _rateFrom = TextEditingController(text: _text(widget.query.dailyRateFrom));
    _rateTo = TextEditingController(text: _text(widget.query.dailyRateTo));
    _yearFrom = TextEditingController(text: _text(widget.query.yearFrom));
    _yearTo = TextEditingController(text: _text(widget.query.yearTo));
  }

  @override
  void didUpdateWidget(covariant _EquipmentFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query.dailyRateFrom != widget.query.dailyRateFrom) {
      _syncController(_rateFrom, widget.query.dailyRateFrom);
    }
    if (oldWidget.query.dailyRateTo != widget.query.dailyRateTo) {
      _syncController(_rateTo, widget.query.dailyRateTo);
    }
    if (oldWidget.query.yearFrom != widget.query.yearFrom) {
      _syncController(_yearFrom, widget.query.yearFrom);
    }
    if (oldWidget.query.yearTo != widget.query.yearTo) {
      _syncController(_yearTo, widget.query.yearTo);
    }
  }

  String _text(num? value) => value?.toString() ?? '';

  void _syncController(TextEditingController c, num? value) {
    final next = _text(value);
    if (c.text != next) c.text = next;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rateFrom.dispose();
    _rateTo.dispose();
    _yearFrom.dispose();
    _yearTo.dispose();
    super.dispose();
  }

  double? _parseDouble(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  int? _parseInt(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  EquipmentQuery _queryFromFields() {
    return widget.query.copyWith(
      dailyRateFrom: _parseDouble(_rateFrom.text),
      dailyRateTo: _parseDouble(_rateTo.text),
      yearFrom: _parseInt(_yearFrom.text),
      yearTo: _parseInt(_yearTo.text),
    );
  }

  void _applyNow() {
    _debounce?.cancel();
    widget.onApply(_queryFromFields());
  }

  void _scheduleApply() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _applyNow);
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.query;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<int?>(
          hint: const Text('Категория'),
          value: query.categoryId,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Все категории')),
            ...widget.catalog.categories.map(
              (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
            ),
          ],
          onChanged: (value) => widget.onApply(query.copyWith(categoryId: value)),
        ),
        DropdownButton<int?>(
          hint: const Text('Бренд'),
          value: query.brandId,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Все бренды')),
            ...widget.catalog.brands.map(
              (b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.name)),
            ),
          ],
          onChanged: (value) => widget.onApply(query.copyWith(brandId: value)),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _rateFrom,
            decoration: const InputDecoration(
              labelText: 'Тариф от',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _scheduleApply(),
            onSubmitted: (_) => _applyNow(),
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _rateTo,
            decoration: const InputDecoration(
              labelText: 'Тариф до',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _scheduleApply(),
            onSubmitted: (_) => _applyNow(),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: _yearFrom,
            decoration: const InputDecoration(
              labelText: 'Год от',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _scheduleApply(),
            onSubmitted: (_) => _applyNow(),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: _yearTo,
            decoration: const InputDecoration(
              labelText: 'Год до',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _scheduleApply(),
            onSubmitted: (_) => _applyNow(),
          ),
        ),
        FilledButton.tonal(
          onPressed: _applyNow,
          child: const Text('Применить'),
        ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.notifier});

  final EquipmentListNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (notifier.selected.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Выбрано: ${notifier.selected.length}'),
          if (!notifier.showDeleted)
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Удалить выбранное',
                  message: 'Пометить выбранные записи как удалённые?',
                );
                if (ok) await notifier.softDeleteSelected();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить выбранное'),
            ),
          if (notifier.showDeleted) ...[
            OutlinedButton(
              onPressed: () => notifier.restoreSelected(),
              child: const Text('Восстановить'),
            ),
            OutlinedButton(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Удалить навсегда',
                  message: 'Выбранные записи будут удалены физически.',
                  confirmLabel: 'Удалить навсегда',
                );
                if (ok) await notifier.hardDeleteSelected();
              },
              child: const Text('Удалить навсегда'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EquipmentCardList extends StatelessWidget {
  const _EquipmentCardList({
    required this.catalog,
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
  });

  final CatalogNotifier catalog;
  final List<Equipment> items;
  final Set<int> selected;
  final void Function(int id) onToggle;
  final void Function(int id) onOpen;
  final Future<void> Function(int id) onSoftDelete;
  final Future<void> Function(int id) onHardDelete;
  final void Function(int id) onRestore;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selected.contains(item.id);
        return Card(
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(item.id),
            ),
            title: Text(item.name),
            subtitle: Text(
              '${item.inventoryNumber} · ${catalog.categoryName(item.categoryId)} · ${item.dailyRate.toStringAsFixed(0)} ₽/сут.',
            ),
            onTap: () => onOpen(item.id),
            trailing: PopupMenuButton<String>(
              onSelected: (action) async {
                switch (action) {
                  case 'open':
                    onOpen(item.id);
                  case 'delete':
                    await onSoftDelete(item.id);
                  case 'restore':
                    onRestore(item.id);
                  case 'hard':
                    await onHardDelete(item.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'open', child: Text('Открыть')),
                if (item.deletedAt == null)
                  const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                if (item.deletedAt != null) ...[
                  const PopupMenuItem(value: 'restore', child: Text('Восстановить')),
                  const PopupMenuItem(
                    value: 'hard',
                    child: Text('Удалить навсегда'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
