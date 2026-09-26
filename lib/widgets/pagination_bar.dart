import 'package:flutter/material.dart';

import '../models/page_result.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.result,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  final PageResult<dynamic> result;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Страница ${result.page} из ${result.totalPages} · всего ${result.total}',
        ),
        DropdownButton<int>(
          value: result.size,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (value) {
            if (value != null) onSizeChanged(value);
          },
        ),
        IconButton(
          tooltip: 'Первая',
          onPressed: result.hasPrevious ? () => onPageChanged(1) : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: 'Предыдущая',
          onPressed:
              result.hasPrevious ? () => onPageChanged(result.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Следующая',
          onPressed:
              result.hasNext ? () => onPageChanged(result.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'Последняя',
          onPressed: result.hasNext
              ? () => onPageChanged(result.totalPages)
              : null,
          icon: const Icon(Icons.last_page),
        ),
      ],
    );
  }
}
