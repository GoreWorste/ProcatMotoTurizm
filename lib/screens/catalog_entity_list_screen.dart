import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/repository_exceptions.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/load_status.dart';
import '../models/named_entity_query.dart';
import '../models/tag.dart';
import '../routing/query_params.dart';
import '../state/named_entity_list_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../core/auth_permissions.dart';
import '../core/layout_breakpoints.dart';
import '../state/auth_notifier.dart';
import '../widgets/list_state_views.dart';
import '../widgets/pagination_bar.dart';

enum CatalogEntityKind { category, brand, tag }

class CatalogEntityListScreen extends StatefulWidget {
  const CatalogEntityListScreen({super.key, required this.kind});

  final CatalogEntityKind kind;

  @override
  State<CatalogEntityListScreen> createState() =>
      _CatalogEntityListScreenState();
}

class _CatalogEntityListScreenState extends State<CatalogEntityListScreen> {
  String? _appliedUri;
  bool _skipUriApply = false;

  String get _basePath => switch (widget.kind) {
        CatalogEntityKind.category => '/categories',
        CatalogEntityKind.brand => '/brands',
        CatalogEntityKind.tag => '/tags',
      };

  String get _title => switch (widget.kind) {
        CatalogEntityKind.category => 'Категории',
        CatalogEntityKind.brand => 'Бренды',
        CatalogEntityKind.tag => 'Теги',
      };

  NamedEntityListNotifier<dynamic> _notifier(BuildContext context) {
    return switch (widget.kind) {
      CatalogEntityKind.category =>
        context.read<NamedEntityListNotifier<Category>>() as NamedEntityListNotifier<dynamic>,
      CatalogEntityKind.brand =>
        context.read<NamedEntityListNotifier<Brand>>() as NamedEntityListNotifier<dynamic>,
      CatalogEntityKind.tag =>
        context.read<NamedEntityListNotifier<Tag>>() as NamedEntityListNotifier<dynamic>,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_skipUriApply) return;

    final uriString = GoRouterState.of(context).uri.toString();
    if (_appliedUri == uriString) return;
    _appliedUri = uriString;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _skipUriApply) return;
      final parsed = namedEntityQueryFromUri(
        GoRouterState.of(context).uri.queryParameters,
      );
      final notifier = _notifier(context);
      if (!_queriesEqual(parsed, notifier.query)) {
        notifier.applyQuery(parsed);
      } else if (notifier.status == LoadStatus.idle ||
          notifier.status == LoadStatus.loading) {
        notifier.load(force: notifier.status == LoadStatus.loading);
      }
    });
  }

  bool _queriesEqual(NamedEntityQuery a, NamedEntityQuery b) {
    return namedEntityQueryToParams(a).toString() ==
        namedEntityQueryToParams(b).toString();
  }

  Future<void> _apply(NamedEntityQuery next) async {
    _skipUriApply = true;
    final notifier = _notifier(context);
    await notifier.applyQuery(next);
    final uri = Uri(
      path: _basePath,
      queryParameters: namedEntityQueryToParams(notifier.query),
    );
    _appliedUri = uri.toString();
    if (mounted && GoRouterState.of(context).uri.toString() != _appliedUri) {
      context.go(_appliedUri!);
    }
    _skipUriApply = false;
  }

  int _idOf(dynamic item) => switch (item) {
        Category c => c.id,
        Brand b => b.id,
        Tag t => t.id,
        _ => 0,
      };

  String _nameOf(dynamic item) => switch (item) {
        Category c => c.name,
        Brand b => b.name,
        Tag t => t.name,
        _ => '',
      };

  DateTime? _deletedAtOf(dynamic item) => switch (item) {
        Category c => c.deletedAt,
        Brand b => b.deletedAt,
        Tag t => t.deletedAt,
        _ => null,
      };

  NamedEntityListNotifier<dynamic> _watchNotifier(BuildContext context) {
    return switch (widget.kind) {
      CatalogEntityKind.category =>
        context.watch<NamedEntityListNotifier<Category>>()
            as NamedEntityListNotifier<dynamic>,
      CatalogEntityKind.brand =>
        context.watch<NamedEntityListNotifier<Brand>>()
            as NamedEntityListNotifier<dynamic>,
      CatalogEntityKind.tag =>
        context.watch<NamedEntityListNotifier<Tag>>()
            as NamedEntityListNotifier<dynamic>,
    };
  }

  @override
  Widget build(BuildContext context) {
    final notifier = _watchNotifier(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => notifier.load(force: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManageCatalog(context.watch<AuthNotifier>())
          ? FloatingActionButton(
              onPressed: () => context.push('$_basePath/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DebouncedSearchField(
                  initialValue: notifier.query.search,
                  hintText: 'Поиск по названию',
                  onChanged: (value) =>
                      _apply(notifier.query.copyWith(search: value)),
                ),
                const SizedBox(height: 8),
                FilterChip(
                  label: const Text('Показать удалённые'),
                  selected: notifier.showDeleted,
                  onSelected: (value) =>
                      _apply(notifier.query.copyWith(includeDeleted: value)),
                ),
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

  Widget _buildBody(NamedEntityListNotifier<dynamic> notifier) {
    if (notifier.status == LoadStatus.error) {
      return ListErrorView(
        error: notifier.error,
        onRetry: () => notifier.load(force: true),
      );
    }
    switch (notifier.status) {
      case LoadStatus.loading:
      case LoadStatus.idle:
        return const ListLoadingView();
      case LoadStatus.error:
        return const SizedBox.shrink();
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const ListEmptyView();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < LayoutBreakpoints.listTableMin) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: notifier.result.items.length,
                itemBuilder: (context, index) {
                  final item = notifier.result.items[index];
                  final id = _idOf(item);
                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: notifier.selected.contains(id),
                        onChanged: (_) => notifier.toggleSelection(id),
                      ),
                      title: Text(_nameOf(item)),
                      onTap: () => context.go('$_basePath/$id'),
                    ),
                  );
                },
              );
            }
            return EntityTable<dynamic>(
              columns: [
                TableColumnSpec(
                  label: 'Название',
                  sortField: 'name',
                  build: (item) => Text(_nameOf(item)),
                ),
              ],
              items: notifier.result.items,
              idOf: _idOf,
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

  Widget _rowActions(dynamic item, NamedEntityListNotifier<dynamic> notifier) {
    final id = _idOf(item);
    return Wrap(
      spacing: 4,
      children: [
        IconButton(
          tooltip: 'Открыть',
          icon: const Icon(Icons.open_in_new),
          onPressed: () => context.go('$_basePath/$id'),
        ),
        if (_deletedAtOf(item) == null)
          IconButton(
            tooltip: 'Удалить',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmSoftDelete(id, notifier),
          )
        else ...[
          IconButton(
            tooltip: 'Восстановить',
            icon: const Icon(Icons.restore),
            onPressed: () => notifier.restore(id),
          ),
          IconButton(
            tooltip: 'Удалить навсегда',
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _confirmHardDelete(id, notifier),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmSoftDelete(
    int id,
    NamedEntityListNotifier<dynamic> notifier,
  ) async {
    final ok = await confirmAction(
      context,
      title: 'Логическое удаление',
      message: 'Пометить запись как удалённую?',
    );
    if (!ok || !mounted) return;
    await notifier.softDelete(id);
  }

  Future<void> _confirmHardDelete(
    int id,
    NamedEntityListNotifier<dynamic> notifier,
  ) async {
    final ok = await confirmAction(
      context,
      title: 'Физическое удаление',
      message: 'Запись будет удалена без возможности восстановления.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    try {
      await notifier.hardDelete(id);
    } on ReferenceInUseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.notifier});

  final NamedEntityListNotifier<dynamic> notifier;

  @override
  Widget build(BuildContext context) {
    if (notifier.selected.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: [
          Text('Выбрано: ${notifier.selected.length}'),
          if (!notifier.showDeleted)
            OutlinedButton(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Удалить выбранное',
                  message: 'Пометить выбранные записи как удалённые?',
                );
                if (ok) await notifier.softDeleteSelected();
              },
              child: const Text('Удалить выбранное'),
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
