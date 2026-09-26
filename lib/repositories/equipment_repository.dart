import '../models/equipment.dart';
import '../models/equipment_query.dart';
import '../models/page_result.dart';

abstract class EquipmentRepository {
  Future<PageResult<Equipment>> find(EquipmentQuery query);

  Future<Equipment?> findById(int id);

  Future<Equipment> create(Equipment item);

  Future<Equipment> update(Equipment item);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids);
}
