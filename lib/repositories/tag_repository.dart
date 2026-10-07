import 'package:dio/dio.dart';

import '../models/tag.dart';
import '../models/named_entity_query.dart';
import '../models/page_result.dart';

abstract class TagRepository {
  Future<PageResult<Tag>> find(
    NamedEntityQuery query, {
    CancelToken? cancelToken,
  });

  Future<List<Tag>> findAll({bool includeDeleted = false});

  Future<Tag?> findById(int id);

  Future<Tag> create(Tag item);

  Future<Tag> update(Tag item);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids);
}
