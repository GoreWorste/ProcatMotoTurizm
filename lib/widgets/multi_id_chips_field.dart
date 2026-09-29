import 'package:flutter/material.dart';

import '../core/validators.dart';

class MultiIdChipsField extends StatelessWidget {
  const MultiIdChipsField({
    super.key,
    required this.label,
    required this.selectedIds,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final List<int> selectedIds;
  final List<({int id, String name})> options;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<List<int>>(
      initialValue: selectedIds,
      validator: (value) =>
          validateIdList(value, 'Выберите хотя бы один вариант'),
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final selected = field.value!.contains(opt.id);
              return FilterChip(
                label: Text(opt.name),
                selected: selected,
                onSelected: (_) {
                  final next = [...field.value!];
                  if (selected) {
                    next.remove(opt.id);
                  } else {
                    next.add(opt.id);
                  }
                  field.didChange(next);
                  onChanged(next);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
