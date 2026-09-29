import '../models/equipment.dart';
import '../models/equipment_query.dart';
import '../models/page_result.dart';
import 'app_data_store.dart';
import 'equipment_repository.dart';

class PersistentEquipmentRepository implements EquipmentRepository {
  PersistentEquipmentRepository(this._store);

  final AppDataStore _store;

  List<Equipment> get _items => _store.equipment;

  @override
  Future<PageResult<Equipment>> find(EquipmentQuery query) async {
    final searchTrim = query.search.trim();
    final delay = searchTrim == '__slow_load__'
        ? const Duration(seconds: 6)
        : const Duration(milliseconds: 250);
    await Future<void>.delayed(delay);

    if (searchTrim == 'Errorr') {
      throw StateError('Симуляция ошибки');
    }

    var list = List<Equipment>.from(_items);

    if (!query.includeDeleted) {
      list = list.where((e) => e.deletedAt == null).toList();
    }

    final search = query.search.trim().toLowerCase();
    if (search.isNotEmpty &&
        search != '__slow_load__' &&
        search != '__error__') {
      list = list
          .where(
            (e) =>
                e.name.toLowerCase().contains(search) ||
                e.inventoryNumber.toLowerCase().contains(search),
          )
          .toList();
    }

    if (query.categoryId != null) {
      list = list.where((e) => e.categoryId == query.categoryId).toList();
    }
    if (query.brandId != null) {
      list = list.where((e) => e.brandId == query.brandId).toList();
    }
    if (query.dailyRateFrom != null) {
      list = list.where((e) => e.dailyRate >= query.dailyRateFrom!).toList();
    }
    if (query.dailyRateTo != null) {
      list = list.where((e) => e.dailyRate <= query.dailyRateTo!).toList();
    }
    if (query.yearFrom != null) {
      list = list.where((e) => e.purchaseYear >= query.yearFrom!).toList();
    }
    if (query.yearTo != null) {
      list = list.where((e) => e.purchaseYear <= query.yearTo!).toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (query.sortField) {
        case 'dailyRate':
          cmp = a.dailyRate.compareTo(b.dailyRate);
        case 'purchaseYear':
          cmp = a.purchaseYear.compareTo(b.purchaseYear);
        case 'inventoryNumber':
          cmp = a.inventoryNumber.compareTo(b.inventoryNumber);
        case 'name':
        default:
          cmp = a.name.compareTo(b.name);
      }
      return query.sortAscending ? cmp : -cmp;
    });

    final total = list.length;
    final page = query.page < 1 ? 1 : query.page;
    final size = query.size < 1 ? 10 : query.size;
    final start = (page - 1) * size;
    final end = start + size;
    final to = end > total ? total : end;
    final pageItems = start >= total ? <Equipment>[] : list.sublist(start, to);

    return PageResult<Equipment>(
      items: pageItems,
      page: page,
      size: size,
      total: total,
    );
  }

  @override
  Future<Equipment?> findById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      return _items.firstWhere((e) => e.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Equipment> create(Equipment item) async {
    final created = item.copyWith(id: _store.equipmentNextId++);
    _items.add(created);
    await _store.persistEquipment();
    return created;
  }

  @override
  Future<Equipment> update(Equipment item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index < 0) {
      throw StateError('Equipment not found');
    }
    _items[index] = item;
    await _store.persistEquipment();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
    await _store.persistEquipment();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((e) => e.id == id);
    await _store.persistEquipment();
  }

  @override
  Future<void> restore(int id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(clearDeletedAt: true);
    await _store.persistEquipment();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var removed = 0;
    for (final id in ids) {
      final index = _items.indexWhere((e) => e.id == id);
      if (index >= 0) {
        _items.removeAt(index);
        removed++;
      }
    }
    if (removed > 0) {
      await _store.persistEquipment();
    }
    return removed;
  }

  @override
  bool isInventoryNumberTaken(String inventoryNumber, {int? exceptId}) {
    final normalized = inventoryNumber.trim().toLowerCase();
    return _items.any(
      (e) =>
          e.inventoryNumber.trim().toLowerCase() == normalized &&
          e.id != exceptId,
    );
  }

  @override
  int countByBrandId(int brandId) =>
      _items.where((e) => e.brandId == brandId && e.deletedAt == null).length;

  @override
  int countByCategoryId(int categoryId) =>
      _items
          .where((e) => e.categoryId == categoryId && e.deletedAt == null)
          .length;

  @override
  List<int> brandIdsForCategory(int categoryId) => _items
      .where((e) => e.categoryId == categoryId)
      .map((e) => e.brandId)
      .toSet()
      .toList();
}
