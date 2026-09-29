import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  const TableColumnSpec({
    required this.label,
    required this.sortField,
    required this.build,
    this.numeric = false,
  });

  final String label;
  final String sortField;
  final bool numeric;
  final Widget Function(T item) build;
}

class EntityTable<T> extends StatelessWidget {
  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    required this.selected,
    required this.onToggleSelect,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.actions,
  });

  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final void Function(int id) onToggleSelect;
  final String sortField;
  final bool sortAscending;
  final void Function(String field) onSort;
  final Widget Function(T item) actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                  sortColumnIndex: _sortIndex(),
                  sortAscending: sortAscending,
                  showCheckboxColumn: true,
                  columns: [
                    ...columns.map(_buildColumn),
                    const DataColumn(label: Text('Действия')),
                  ],
                  rows: items.map((item) {
                    final id = idOf(item);
                    final isSelected = selected.contains(id);
                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: (_) => onToggleSelect(id),
                      cells: [
                        ...columns.map((c) => DataCell(c.build(item))),
                        DataCell(actions(item)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
      },
    );
  }

  int? _sortIndex() {
    final index = columns.indexWhere((c) => c.sortField == sortField);
    if (index < 0) return null;
    return index;
  }

  DataColumn _buildColumn(TableColumnSpec<T> spec) {
    return DataColumn(
      numeric: spec.numeric,
      label: Text(spec.label),
      onSort: (_, _) => onSort(spec.sortField),
    );
  }
}
