import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/client_query.dart';
import '../models/load_status.dart';
import '../routing/query_params.dart';
import '../state/client_list_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_views.dart';
import '../widgets/pagination_bar.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  String? _appliedUri;
  bool _skipUriApply = false;

  static const _cities = [
    'Екатеринбург',
    'Челябинск',
    'Пермь',
    'Тюмень',
  ];

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
          clientQueryFromUri(GoRouterState.of(context).uri.queryParameters);
      final notifier = context.read<ClientListNotifier>();
      if (!_queriesEqual(parsed, notifier.query)) {
        notifier.applyQuery(parsed);
      } else if (notifier.status == LoadStatus.idle) {
        notifier.load();
      }
    });
  }

  bool _queriesEqual(ClientQuery a, ClientQuery b) {
    return clientQueryToParams(a).toString() ==
        clientQueryToParams(b).toString();
  }

  Future<void> _apply(ClientQuery next) async {
    _skipUriApply = true;
    final notifier = context.read<ClientListNotifier>();
    await notifier.applyQuery(next);
    final uri = Uri(
      path: '/clients',
      queryParameters: clientQueryToParams(notifier.query),
    );
    _appliedUri = uri.toString();
    if (mounted && GoRouterState.of(context).uri.toString() != _appliedUri) {
      context.go(_appliedUri!);
    }
    _skipUriApply = false;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClientListNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Клиенты')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/clients/new'),
        tooltip: 'Добавить клиента',
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
                  hintText: 'Поиск по ФИО, почте или телефону',
                  onChanged: (value) =>
                      _apply(notifier.query.copyWith(search: value)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Показать удалённые'),
                      selected: notifier.showDeleted,
                      onSelected: (value) => _apply(
                        notifier.query.copyWith(includeDeleted: value),
                      ),
                    ),
                    DropdownButton<String?>(
                      hint: const Text('Город'),
                      value: notifier.query.city,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Все города'),
                        ),
                        ..._cities.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c,
                            child: Text(c),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          _apply(notifier.query.copyWith(city: value)),
                    ),
                  ],
                ),
                _ClientSelectionBar(notifier: notifier),
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

  Widget _buildBody(ClientListNotifier notifier) {
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
            if (constraints.maxWidth < 600) {
              return _ClientCardList(
                items: notifier.result.items,
                selected: notifier.selected,
                onToggle: notifier.toggleSelection,
                onOpen: (id) => context.go('/clients/$id'),
                onSoftDelete: _confirmSoftDelete,
                onHardDelete: _confirmHardDelete,
                onRestore: (id) => notifier.restore(id),
              );
            }
            return EntityTable<Client>(
              columns: _columns,
              items: notifier.result.items,
              idOf: (c) => c.id,
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

  List<TableColumnSpec<Client>> get _columns => [
        TableColumnSpec(
          label: 'ФИО',
          sortField: 'fullName',
          build: (c) => Text(c.fullName),
        ),
        TableColumnSpec(
          label: 'Почта',
          sortField: 'email',
          build: (c) => Text(c.email),
        ),
        TableColumnSpec(
          label: 'Телефон',
          sortField: 'phone',
          build: (c) => Text(c.phone),
        ),
        TableColumnSpec(
          label: 'Город',
          sortField: 'city',
          build: (c) => Text(c.city),
        ),
        TableColumnSpec(
          label: 'Регистрация',
          sortField: 'registeredAt',
          build: (c) => Text(
            '${c.registeredAt.day.toString().padLeft(2, '0')}.'
            '${c.registeredAt.month.toString().padLeft(2, '0')}.'
            '${c.registeredAt.year}',
          ),
        ),
      ];

  Widget _rowActions(Client item, ClientListNotifier notifier) {
    return Wrap(
      spacing: 4,
      children: [
        IconButton(
          tooltip: 'Открыть',
          icon: const Icon(Icons.open_in_new),
          onPressed: () => context.go('/clients/${item.id}'),
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
      message: 'Пометить клиента как удалённого?',
    );
    if (!ok || !mounted) return;
    await context.read<ClientListNotifier>().softDelete(id);
  }

  Future<void> _confirmHardDelete(int id) async {
    final ok = await confirmAction(
      context,
      title: 'Физическое удаление',
      message: 'Запись будет удалена без возможности восстановления.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    await context.read<ClientListNotifier>().hardDelete(id);
  }
}

class _ClientSelectionBar extends StatelessWidget {
  const _ClientSelectionBar({required this.notifier});

  final ClientListNotifier notifier;

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
                  message: 'Пометить выбранных клиентов как удалённых?',
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

class _ClientCardList extends StatelessWidget {
  const _ClientCardList({
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
  });

  final List<Client> items;
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
        return Card(
          child: ListTile(
            leading: Checkbox(
              value: selected.contains(item.id),
              onChanged: (_) => onToggle(item.id),
            ),
            title: Text(item.fullName),
            subtitle: Text('${item.phone} · ${item.city}'),
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
