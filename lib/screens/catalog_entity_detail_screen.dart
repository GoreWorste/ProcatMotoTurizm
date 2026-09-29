import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/repository_exceptions.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/load_status.dart';
import '../models/tag.dart';
import '../repositories/brand_repository.dart';
import '../repositories/category_repository.dart';
import '../routing/query_params.dart';
import '../state/named_entity_list_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/list_state_views.dart';
import 'catalog_entity_list_screen.dart';

class CatalogEntityDetailScreen extends StatefulWidget {
  const CatalogEntityDetailScreen({
    super.key,
    required this.kind,
    required this.id,
  });

  final CatalogEntityKind kind;
  final int id;

  @override
  State<CatalogEntityDetailScreen> createState() =>
      _CatalogEntityDetailScreenState();
}

class _CatalogEntityDetailScreenState extends State<CatalogEntityDetailScreen> {
  String get _basePath => switch (widget.kind) {
        CatalogEntityKind.category => '/categories',
        CatalogEntityKind.brand => '/brands',
        CatalogEntityKind.tag => '/tags',
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier(context).loadDetail(widget.id);
    });
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final notifier = _notifier(context);
    final params = namedEntityQueryToParams(notifier.query);
    context.go(Uri(path: _basePath, queryParameters: params).toString());
  }

  int? _linkCount(BuildContext context, dynamic item) {
    return switch (widget.kind) {
      CatalogEntityKind.category => context
          .read<CategoryRepository>()
          .countEquipmentLinks((item as Category).id),
      CatalogEntityKind.brand => context
          .read<BrandRepository>()
          .countEquipmentLinks((item as Brand).id),
      CatalogEntityKind.tag => null,
    };
  }

  String _name(dynamic item) => switch (item) {
        Category c => c.name,
        Brand b => b.name,
        Tag t => t.name,
        _ => '',
      };

  DateTime? _deletedAt(dynamic item) => switch (item) {
        Category c => c.deletedAt,
        Brand b => b.deletedAt,
        Tag t => t.deletedAt,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final notifier = switch (widget.kind) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (widget.kind) {
          CatalogEntityKind.category => 'Категория',
          CatalogEntityKind.brand => 'Бренд',
          CatalogEntityKind.tag => 'Тег',
        }),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBack(context),
        ),
        actions: [
          if (_deletedAt(notifier.detailItem) == null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push('$_basePath/${widget.id}/edit'),
            ),
        ],
      ),
      body: _buildBody(context, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NamedEntityListNotifier<dynamic> notifier,
  ) {
    switch (notifier.detailStatus) {
      case LoadStatus.loading:
      case LoadStatus.idle:
        return const ListLoadingView();
      case LoadStatus.error:
        return ListErrorView(
          message: notifier.detailError ?? 'Ошибка',
          onRetry: () => notifier.loadDetail(widget.id),
        );
      case LoadStatus.success:
        final item = notifier.detailItem;
        if (item == null) return const ListEmptyView();
        final links = _linkCount(context, item);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_name(item), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _DetailRow('ID', '${widget.id}'),
              if (links != null)
                _DetailRow('Связанное оборудование', '$links'),
              _DetailRow(
                'Удалено',
                _deletedAt(item) == null
                    ? 'нет'
                    : _deletedAt(item)!.toLocal().toString(),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [
                  if (_deletedAt(item) == null)
                    FilledButton.icon(
                      onPressed: () async {
                        final ok = await confirmAction(
                          context,
                          title: 'Удалить',
                          message: 'Пометить запись как удалённую?',
                        );
                        if (!ok || !mounted) return;
                        await notifier.softDelete(widget.id);
                        await notifier.loadDetail(widget.id);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Логическое удаление'),
                    ),
                  if (_deletedAt(item) != null) ...[
                    OutlinedButton(
                      onPressed: () async {
                        await notifier.restore(widget.id);
                        await notifier.loadDetail(widget.id);
                      },
                      child: const Text('Восстановить'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final ok = await confirmAction(
                          context,
                          title: 'Удалить навсегда',
                          message:
                              'Запись будет удалена без возможности восстановления.',
                          confirmLabel: 'Удалить навсегда',
                        );
                        if (!ok || !mounted) return;
                        try {
                          await notifier.hardDelete(widget.id);
                          if (!mounted) return;
                          _goBack(context);
                        } on ReferenceInUseException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      },
                      child: const Text('Физическое удаление'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
