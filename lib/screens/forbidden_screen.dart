import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 72, color: Colors.orange.shade800),
              const SizedBox(height: 16),
              Text(
                '403 — недостаточно прав',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Эта страница доступна только пользователям с нужной ролью. '
                'Кнопки в интерфейсе скрыты, но прямой URL всё равно проверяется redirect.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/equipment'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
