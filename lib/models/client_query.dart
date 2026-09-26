class ClientQuery {
  static const Object _unset = Object();

  const ClientQuery({
    this.search = '',
    this.city,
    this.sortField = 'fullName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  final String search;
  final String? city;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  ClientQuery copyWith({
    Object? search = _unset,
    Object? city = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    final nextSearch = search == _unset ? this.search : search as String?;
    final nextCity = city == _unset ? this.city : city as String?;
    final nextSortField = sortField ?? this.sortField;
    final nextSortAscending = sortAscending ?? this.sortAscending;
    final nextSize = size ?? this.size;
    final nextIncludeDeleted = includeDeleted ?? this.includeDeleted;

    final filtersChanged = search != _unset ||
        city != _unset ||
        sortField != null ||
        sortAscending != null ||
        size != null ||
        includeDeleted != null;

    final nextPage = page ?? (filtersChanged ? 1 : this.page);

    return ClientQuery(
      search: nextSearch ?? '',
      city: nextCity,
      sortField: nextSortField,
      sortAscending: nextSortAscending,
      page: nextPage,
      size: nextSize,
      includeDeleted: nextIncludeDeleted,
    );
  }

  ClientQuery withPage(int page) => copyWith(page: page);

  ClientQuery withSort(String field, bool ascending) =>
      copyWith(sortField: field, sortAscending: ascending);
}
