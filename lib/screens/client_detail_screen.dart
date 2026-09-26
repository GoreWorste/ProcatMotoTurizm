import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/load_status.dart';
import '../routing/query_params.dart';
import '../state/client_list_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/list_state_views.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientListNotifier>().loadDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClientListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка клиента'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(notifier),
    );
  }

  Widget _buildBody(ClientListNotifier notifier) {
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.fullName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _DetailRow('ID', '${item.id}'),
              _DetailRow('Телефон', item.phone),
              _DetailRow('Город', item.city),
              _DetailRow(
                'Дата регистрации',
                item.registeredAt.toLocal().toString(),
              ),
              _DetailRow(
                'Удалён',
                item.deletedAt == null
                    ? 'нет'
                    : item.deletedAt!.toLocal().toString(),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [
                  if (item.deletedAt == null)
                    FilledButton.icon(
                      onPressed: () async {
                        final ok = await confirmAction(
                          context,
                          title: 'Удалить',
                          message: 'Пометить клиента как удалённого?',
                        );
                        if (!ok || !mounted) return;
                        await notifier.softDelete(item.id);
                        await notifier.loadDetail(item.id);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Логическое удаление'),
                    ),
                  if (item.deletedAt != null) ...[
                    OutlinedButton(
                      onPressed: () async {
                        await notifier.restore(item.id);
                        await notifier.loadDetail(item.id);
                      },
                      child: const Text('Восстановить'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final ok = await confirmAction(
                          context,
                          title: 'Удалить навсегда',
                          message: 'Запись будет удалена без возможности восстановления.',
                          confirmLabel: 'Удалить навсегда',
                        );
                        if (!ok || !mounted) return;
                        final params = clientQueryToParams(notifier.query);
                        await notifier.hardDelete(item.id);
                        if (!mounted) return;
                        context.go(
                          Uri(
                            path: '/clients',
                            queryParameters: params,
                          ).toString(),
                        );
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
            width: 180,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
