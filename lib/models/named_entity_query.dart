class NamedEntityQuery {
  static const Object _unset = Object();

  const NamedEntityQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  NamedEntityQuery copyWith({
    Object? search = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    final nextSearch = search == _unset ? this.search : search as String?;
    final nextSortField = sortField ?? this.sortField;
    final nextSortAscending = sortAscending ?? this.sortAscending;
    final nextSize = size ?? this.size;
    final nextIncludeDeleted = includeDeleted ?? this.includeDeleted;

    final filtersChanged = search != _unset ||
        sortField != null ||
        sortAscending != null ||
        size != null ||
        includeDeleted != null;

    final nextPage = page ?? (filtersChanged ? 1 : this.page);

    return NamedEntityQuery(
      search: nextSearch ?? '',
      sortField: nextSortField,
      sortAscending: nextSortAscending,
      page: nextPage,
      size: nextSize,
      includeDeleted: nextIncludeDeleted,
    );
  }

  NamedEntityQuery withSort(String field, bool ascending) =>
      copyWith(sortField: field, sortAscending: ascending);
}
