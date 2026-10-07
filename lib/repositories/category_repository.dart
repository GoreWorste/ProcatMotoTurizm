import 'package:dio/dio.dart';

import '../models/category.dart';
import '../models/named_entity_query.dart';
import '../models/page_result.dart';

abstract class CategoryRepository {
  Future<PageResult<Category>> find(
    NamedEntityQuery query, {
    CancelToken? cancelToken,
  });

  Future<List<Category>> findAll({bool includeDeleted = false});

  Future<Category?> findById(int id);

  Future<Category> create(Category item);

  Future<Category> update(Category item);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  int countEquipmentLinks(int categoryId);

  Future<int> deleteMany(List<int> ids);
}
