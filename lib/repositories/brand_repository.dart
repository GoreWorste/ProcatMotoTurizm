import '../models/brand.dart';
import '../models/named_entity_query.dart';
import '../models/page_result.dart';

abstract class BrandRepository {
  Future<PageResult<Brand>> find(NamedEntityQuery query);

  Future<List<Brand>> findAll({bool includeDeleted = false});

  Future<Brand?> findById(int id);

  Future<Brand> create(Brand item);

  Future<Brand> update(Brand item);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  int countEquipmentLinks(int brandId);

  Future<int> deleteMany(List<int> ids);
}
