import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/equipment.dart';
import '../../models/equipment_query.dart';
import '../../models/page_result.dart';
import '../equipment_repository.dart';
import 'api_page_parser.dart';

class ApiEquipmentRepository implements EquipmentRepository {
  ApiEquipmentRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _queryMap(EquipmentQuery q) => {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        if (q.categoryId != null) 'categoryId': q.categoryId,
        if (q.brandId != null) 'brandId': q.brandId,
        if (q.dailyRateFrom != null) 'dailyRateFrom': q.dailyRateFrom,
        if (q.dailyRateTo != null) 'dailyRateTo': q.dailyRateTo,
        if (q.yearFrom != null) 'yearFrom': q.yearFrom,
        if (q.yearTo != null) 'yearTo': q.yearTo,
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _writeBody(Equipment item) => {
        'name': item.name,
        'inventoryNumber': item.inventoryNumber,
        'categoryId': item.categoryId,
        'brandId': item.brandId,
        'purchaseYear': item.purchaseYear,
        'dailyRate': item.dailyRate,
        'condition': item.condition,
        'unitsTotal': item.unitsTotal,
        'unitsAvailable': item.unitsAvailable,
        'tagIds': item.tagIds,
      };

  @override
  Future<PageResult<Equipment>> find(
    EquipmentQuery query, {
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/equipment',
          queryParameters: _queryMap(query),
          cancelToken: cancelToken,
        );
        return parsePage(response.data ?? {}, Equipment.fromJson);
      });

  @override
  Future<Equipment?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get<Map<String, dynamic>>('/equipment/$id');
        return Equipment.fromJson(response.data ?? {});
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Equipment> create(Equipment item) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/equipment',
          data: _writeBody(item),
        );
        return Equipment.fromJson(response.data ?? {});
      });

  @override
  Future<Equipment> update(Equipment item) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/equipment/${item.id}',
          data: _writeBody(item),
        );
        return Equipment.fromJson(response.data ?? {});
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete('/equipment/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete('/equipment/$id', queryParameters: {'hard': true}),
      );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/equipment/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/equipment/bulk-delete',
          data: {'ids': ids},
        );
        return response.data?['deleted'] as int? ?? 0;
      });

  @override
  bool isInventoryNumberTaken(String inventoryNumber, {int? exceptId}) => false;

  @override
  int countByBrandId(int brandId) => 0;

  @override
  int countByCategoryId(int categoryId) => 0;

  @override
  List<int> brandIdsForCategory(int categoryId) => [];

  Future<List<int>> fetchBrandIdsForCategory(int categoryId) => guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/equipment/meta/brand-ids',
          queryParameters: {'categoryId': categoryId},
        );
        final ids = response.data?['brandIds'];
        if (ids is List) return ids.cast<int>();
        return <int>[];
      });
}
