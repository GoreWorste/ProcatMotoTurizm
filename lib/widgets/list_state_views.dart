import 'package:flutter/material.dart';

import '../core/api_error_presentation.dart';
import '../core/api_exceptions.dart';

class ListLoadingView extends StatelessWidget {
  const ListLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ListEmptyView extends StatelessWidget {
  const ListEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'Ничего не найдено по заданным условиям',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ListErrorView extends StatelessWidget {
  const ListErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connection = isConnectionFailure(error);
    final presentation = connection
        ? connectionFailurePresentation(error)
        : null;
    final fallbackMessage = describeError(error ?? 'Ошибка загрузки');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 72, color: Colors.red.shade700),
              const SizedBox(height: 16),
              Text(
                presentation?.title ?? 'Ошибка загрузки',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                presentation?.summary ?? fallbackMessage,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (presentation != null) ...[
                const SizedBox(height: 20),
                _HintCard(
                  icon: Icons.dns_outlined,
                  title: 'Сервер не отвечает',
                  lines: presentation.serverChecks,
                  color: Colors.orange.shade50,
                  borderColor: Colors.orange.shade200,
                ),
                const SizedBox(height: 12),
                _HintCard(
                  icon: Icons.shield_outlined,
                  title: 'CORS (браузер блокирует API)',
                  lines: presentation.corsChecks,
                  color: Colors.blue.shade50,
                  borderColor: Colors.blue.shade200,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.title,
    required this.lines,
    required this.color,
    required this.borderColor,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $line', style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}
