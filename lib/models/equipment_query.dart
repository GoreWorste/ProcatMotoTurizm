class EquipmentQuery {
  static const Object _unset = Object();

  const EquipmentQuery({
    this.search = '',
    this.categoryId,
    this.brandId,
    this.dailyRateFrom,
    this.dailyRateTo,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  final String search;
  final int? categoryId;
  final int? brandId;
  final double? dailyRateFrom;
  final double? dailyRateTo;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  EquipmentQuery copyWith({
    Object? search = _unset,
    Object? categoryId = _unset,
    Object? brandId = _unset,
    Object? dailyRateFrom = _unset,
    Object? dailyRateTo = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    final nextSearch = search == _unset ? this.search : search as String?;
    final nextCategoryId =
        categoryId == _unset ? this.categoryId : categoryId as int?;
    final nextBrandId = brandId == _unset ? this.brandId : brandId as int?;
    final nextDailyRateFrom = dailyRateFrom == _unset
        ? this.dailyRateFrom
        : dailyRateFrom as double?;
    final nextDailyRateTo =
        dailyRateTo == _unset ? this.dailyRateTo : dailyRateTo as double?;
    final nextYearFrom =
        yearFrom == _unset ? this.yearFrom : yearFrom as int?;
    final nextYearTo = yearTo == _unset ? this.yearTo : yearTo as int?;
    final nextSortField = sortField ?? this.sortField;
    final nextSortAscending = sortAscending ?? this.sortAscending;
    final nextSize = size ?? this.size;
    final nextIncludeDeleted = includeDeleted ?? this.includeDeleted;

    final filtersChanged = search != _unset ||
        categoryId != _unset ||
        brandId != _unset ||
        dailyRateFrom != _unset ||
        dailyRateTo != _unset ||
        yearFrom != _unset ||
        yearTo != _unset ||
        sortField != null ||
        sortAscending != null ||
        size != null ||
        includeDeleted != null;

    final nextPage = page ?? (filtersChanged ? 1 : this.page);

    return EquipmentQuery(
      search: nextSearch ?? '',
      categoryId: nextCategoryId,
      brandId: nextBrandId,
      dailyRateFrom: nextDailyRateFrom,
      dailyRateTo: nextDailyRateTo,
      yearFrom: nextYearFrom,
      yearTo: nextYearTo,
      sortField: nextSortField,
      sortAscending: nextSortAscending,
      page: nextPage,
      size: nextSize,
      includeDeleted: nextIncludeDeleted,
    );
  }

  EquipmentQuery withPage(int page) => copyWith(page: page);

  EquipmentQuery withSort(String field, bool ascending) =>
      copyWith(sortField: field, sortAscending: ascending);
}
