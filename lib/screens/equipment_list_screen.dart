import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/catalog_data.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parsed =
        equipmentQueryFromUri(GoRouterState.of(context).uri.queryParameters);
    final notifier = context.read<EquipmentListNotifier>();
    if (!_queriesEqual(parsed, notifier.query)) {
      notifier.applyQuery(parsed);
    } else if (notifier.status == LoadStatus.idle) {
      notifier.load();
    }
  }

  bool _queriesEqual(EquipmentQuery a, EquipmentQuery b) {
    return equipmentQueryToParams(a).toString() ==
        equipmentQueryToParams(b).toString();
  }

  void _syncUrl(EquipmentQuery query) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = Uri(
        path: '/equipment',
        queryParameters: equipmentQueryToParams(query),
      );
      final current = GoRouterState.of(context).uri.toString();
      if (current != uri.toString()) {
        context.go(uri.toString());
      }
    });
  }

  Future<void> _apply(EquipmentQuery next) async {
    final notifier = context.read<EquipmentListNotifier>();
    await notifier.applyQuery(next);
    _syncUrl(notifier.query);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EquipmentListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оборудование'),
        actions: [
          TextButton(
            onPressed: () => context.go('/clients'),
            child: const Text('Клиенты'),
          ),
        ],
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
                if (_filtersExpanded) _EquipmentFilters(query: notifier.query, onApply: _apply),
                _SelectionBar(notifier: notifier),
              ],
            ),
          ),
          Expanded(child: _buildBody(notifier)),
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

  Widget _buildBody(EquipmentListNotifier notifier) {
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
              columns: _columns,
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

  List<TableColumnSpec<Equipment>> get _columns => [
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
          build: (e) => Text(categoryName(e.categoryId)),
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

class _EquipmentFilters extends StatelessWidget {
  const _EquipmentFilters({required this.query, required this.onApply});

  final EquipmentQuery query;
  final Future<void> Function(EquipmentQuery) onApply;

  @override
  Widget build(BuildContext context) {
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
            ...equipmentCategories.map(
              (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
            ),
          ],
          onChanged: (value) => onApply(query.copyWith(categoryId: value)),
        ),
        DropdownButton<int?>(
          hint: const Text('Бренд'),
          value: query.brandId,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Все бренды')),
            ...equipmentBrands.map(
              (b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.name)),
            ),
          ],
          onChanged: (value) => onApply(query.copyWith(brandId: value)),
        ),
        SizedBox(
          width: 120,
          child: TextFormField(
            key: ValueKey('rateFrom-${query.dailyRateFrom}'),
            initialValue: query.dailyRateFrom?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Тариф от',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (v) => onApply(
              query.copyWith(
                dailyRateFrom: v.isEmpty ? null : double.tryParse(v),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: TextFormField(
            key: ValueKey('rateTo-${query.dailyRateTo}'),
            initialValue: query.dailyRateTo?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Тариф до',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (v) => onApply(
              query.copyWith(
                dailyRateTo: v.isEmpty ? null : double.tryParse(v),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextFormField(
            key: ValueKey('yearFrom-${query.yearFrom}'),
            initialValue: query.yearFrom?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Год от',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (v) => onApply(
              query.copyWith(yearFrom: v.isEmpty ? null : int.tryParse(v)),
            ),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextFormField(
            key: ValueKey('yearTo-${query.yearTo}'),
            initialValue: query.yearTo?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Год до',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (v) => onApply(
              query.copyWith(yearTo: v.isEmpty ? null : int.tryParse(v)),
            ),
          ),
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
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
  });

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
              '${item.inventoryNumber} · ${categoryName(item.categoryId)} · ${item.dailyRate.toStringAsFixed(0)} ₽/сут.',
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
