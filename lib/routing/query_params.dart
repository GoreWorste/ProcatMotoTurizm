import '../models/client_query.dart';
import '../models/equipment_query.dart';
import '../models/named_entity_query.dart';

EquipmentQuery equipmentQueryFromUri(Map<String, String> params) {
  return EquipmentQuery(
    search: params['search'] ?? '',
    categoryId: _parseInt(params['categoryId']),
    brandId: _parseInt(params['brandId']),
    dailyRateFrom: _parseDouble(params['dailyRateFrom']),
    dailyRateTo: _parseDouble(params['dailyRateTo']),
    yearFrom: _parseInt(params['yearFrom']),
    yearTo: _parseInt(params['yearTo']),
    sortField: _parseSortField(params['sort'], defaultField: 'name'),
    sortAscending: _parseSortAscending(params['sort']),
    page: _parseInt(params['page']) ?? 1,
    size: _parseInt(params['size']) ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

ClientQuery clientQueryFromUri(Map<String, String> params) {
  return ClientQuery(
    search: params['search'] ?? '',
    city: params['city'],
    sortField: _parseSortField(params['sort'], defaultField: 'fullName'),
    sortAscending: _parseSortAscending(params['sort']),
    page: _parseInt(params['page']) ?? 1,
    size: _parseInt(params['size']) ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

Map<String, String> equipmentQueryToParams(EquipmentQuery query) {
  final map = <String, String>{};
  if (query.search.isNotEmpty) map['search'] = query.search;
  if (query.categoryId != null) map['categoryId'] = '${query.categoryId}';
  if (query.brandId != null) map['brandId'] = '${query.brandId}';
  if (query.dailyRateFrom != null) {
    map['dailyRateFrom'] = query.dailyRateFrom!.toString();
  }
  if (query.dailyRateTo != null) map['dailyRateTo'] = query.dailyRateTo!.toString();
  if (query.yearFrom != null) map['yearFrom'] = '${query.yearFrom}';
  if (query.yearTo != null) map['yearTo'] = '${query.yearTo}';
  map['sort'] = '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}';
  map['page'] = '${query.page}';
  map['size'] = '${query.size}';
  if (query.includeDeleted) map['includeDeleted'] = 'true';
  return map;
}

Map<String, String> clientQueryToParams(ClientQuery query) {
  final map = <String, String>{};
  if (query.search.isNotEmpty) map['search'] = query.search;
  if (query.city != null && query.city!.isNotEmpty) map['city'] = query.city!;
  map['sort'] = '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}';
  map['page'] = '${query.page}';
  map['size'] = '${query.size}';
  if (query.includeDeleted) map['includeDeleted'] = 'true';
  return map;
}

int? _parseInt(String? value) {
  if (value == null || value.isEmpty) return null;
  return int.tryParse(value);
}

double? _parseDouble(String? value) {
  if (value == null || value.isEmpty) return null;
  return double.tryParse(value);
}

String _parseSortField(String? sort, {required String defaultField}) {
  if (sort == null || sort.isEmpty) return defaultField;
  final parts = sort.split(',');
  return parts.first.isEmpty ? defaultField : parts.first;
}

bool _parseSortAscending(String? sort) {
  if (sort == null || sort.isEmpty) return true;
  final parts = sort.split(',');
  if (parts.length < 2) return true;
  return parts[1].toLowerCase() != 'desc';
}

NamedEntityQuery namedEntityQueryFromUri(Map<String, String> params) {
  return NamedEntityQuery(
    search: params['search'] ?? '',
    sortField: _parseSortField(params['sort'], defaultField: 'name'),
    sortAscending: _parseSortAscending(params['sort']),
    page: _parseInt(params['page']) ?? 1,
    size: _parseInt(params['size']) ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

Map<String, String> namedEntityQueryToParams(NamedEntityQuery query) {
  final map = <String, String>{};
  if (query.search.isNotEmpty) map['search'] = query.search;
  map['sort'] = '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}';
  map['page'] = '${query.page}';
  map['size'] = '${query.size}';
  if (query.includeDeleted) map['includeDeleted'] = 'true';
  return map;
}
