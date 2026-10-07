import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/brand.dart';
import '../../models/category.dart';
import '../../models/named_entity_query.dart';
import '../../models/page_result.dart';
import '../../models/tag.dart';
import '../brand_repository.dart';
import '../category_repository.dart';
import '../tag_repository.dart';
import 'api_page_parser.dart';

Map<String, dynamic> _namedQuery(NamedEntityQuery q) => {
      if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
      'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
      'page': q.page,
      'size': q.size,
      if (q.includeDeleted) 'includeDeleted': true,
    };

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResult<Category>> find(
    NamedEntityQuery query, {
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/categories',
          queryParameters: _namedQuery(query),
          cancelToken: cancelToken,
        );
        return parsePage(response.data ?? {}, Category.fromJson);
      });

  @override
  Future<List<Category>> findAll({bool includeDeleted = false}) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/categories',
          queryParameters: {
            'page': 1,
            'size': 500,
            if (includeDeleted) 'includeDeleted': true,
          },
        );
        return parsePage(response.data ?? {}, Category.fromJson).items;
      });

  @override
  Future<Category?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get<Map<String, dynamic>>('/categories/$id');
        return Category.fromJson(response.data ?? {});
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Category> create(Category item) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/categories',
          data: {'name': item.name},
        );
        return Category.fromJson(response.data ?? {});
      });

  @override
  Future<Category> update(Category item) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/categories/${item.id}',
          data: {'name': item.name},
        );
        return Category.fromJson(response.data ?? {});
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete('/categories/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete('/categories/$id', queryParameters: {'hard': true}),
      );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/categories/$id/restore'));

  @override
  int countEquipmentLinks(int categoryId) => 0;

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/categories/bulk-delete',
          data: {'ids': ids},
        );
        return response.data?['deleted'] as int? ?? 0;
      });
}

class ApiBrandRepository implements BrandRepository {
  ApiBrandRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResult<Brand>> find(
    NamedEntityQuery query, {
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/brands',
          queryParameters: _namedQuery(query),
          cancelToken: cancelToken,
        );
        return parsePage(response.data ?? {}, Brand.fromJson);
      });

  @override
  Future<List<Brand>> findAll({bool includeDeleted = false}) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/brands',
          queryParameters: {
            'page': 1,
            'size': 500,
            if (includeDeleted) 'includeDeleted': true,
          },
        );
        return parsePage(response.data ?? {}, Brand.fromJson).items;
      });

  @override
  Future<Brand?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get<Map<String, dynamic>>('/brands/$id');
        return Brand.fromJson(response.data ?? {});
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Brand> create(Brand item) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/brands',
          data: {'name': item.name},
        );
        return Brand.fromJson(response.data ?? {});
      });

  @override
  Future<Brand> update(Brand item) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/brands/${item.id}',
          data: {'name': item.name},
        );
        return Brand.fromJson(response.data ?? {});
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/brands/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete('/brands/$id', queryParameters: {'hard': true}),
      );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/brands/$id/restore'));

  @override
  int countEquipmentLinks(int brandId) => 0;

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/brands/bulk-delete',
          data: {'ids': ids},
        );
        return response.data?['deleted'] as int? ?? 0;
      });
}

class ApiTagRepository implements TagRepository {
  ApiTagRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResult<Tag>> find(
    NamedEntityQuery query, {
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/tags',
          queryParameters: _namedQuery(query),
          cancelToken: cancelToken,
        );
        return parsePage(response.data ?? {}, Tag.fromJson);
      });

  @override
  Future<List<Tag>> findAll({bool includeDeleted = false}) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/tags',
          queryParameters: {
            'page': 1,
            'size': 500,
            if (includeDeleted) 'includeDeleted': true,
          },
        );
        return parsePage(response.data ?? {}, Tag.fromJson).items;
      });

  @override
  Future<Tag?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get<Map<String, dynamic>>('/tags/$id');
        return Tag.fromJson(response.data ?? {});
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Tag> create(Tag item) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/tags',
          data: {'name': item.name},
        );
        return Tag.fromJson(response.data ?? {});
      });

  @override
  Future<Tag> update(Tag item) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/tags/${item.id}',
          data: {'name': item.name},
        );
        return Tag.fromJson(response.data ?? {});
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/tags/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete('/tags/$id', queryParameters: {'hard': true}),
      );

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/tags/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/tags/bulk-delete',
          data: {'ids': ids},
        );
        return response.data?['deleted'] as int? ?? 0;
      });
}
