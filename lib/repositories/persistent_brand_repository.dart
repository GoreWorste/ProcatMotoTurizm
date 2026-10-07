import '../core/repository_exceptions.dart';
import 'package:dio/dio.dart';

import '../models/brand.dart';
import '../models/named_entity_query.dart';
import '../models/page_result.dart';
import 'app_data_store.dart';
import 'brand_repository.dart';
import 'named_entity_find.dart';

class PersistentBrandRepository implements BrandRepository {
  PersistentBrandRepository(this._store);

  final AppDataStore _store;

  List<Brand> get _items => _store.brands;

  @override
  Future<PageResult<Brand>> find(
    NamedEntityQuery query, {
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (query.search.trim() == '__error__') {
      throw StateError('Симуляция ошибки загрузки');
    }
    return findNamedPage(
      source: _items,
      query: query,
      nameOf: (b) => b.name,
      deletedAtOf: (b) => b.deletedAt,
    );
  }

  @override
  Future<List<Brand>> findAll({bool includeDeleted = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    var list = List<Brand>.from(_items);
    if (!includeDeleted) {
      list = list.where((b) => b.deletedAt == null).toList();
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<Brand?> findById(int id) async {
    try {
      return _items.firstWhere((b) => b.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Brand> create(Brand item) async {
    final created = item.copyWith(id: _store.brandNextId++);
    _items.add(created);
    await _store.persistBrands();
    return created;
  }

  @override
  Future<Brand> update(Brand item) async {
    final index = _items.indexWhere((b) => b.id == item.id);
    if (index < 0) throw StateError('Brand not found');
    _items[index] = item;
    await _store.persistBrands();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _items.indexWhere((b) => b.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
    await _store.persistBrands();
  }

  @override
  Future<void> hardDelete(int id) async {
    final count = countEquipmentLinks(id);
    if (count > 0) {
      throw ReferenceInUseException(
        'Нельзя удалить бренд: связано единиц оборудования — $count',
        count: count,
      );
    }
    _items.removeWhere((b) => b.id == id);
    await _store.persistBrands();
  }

  @override
  Future<void> restore(int id) async {
    final index = _items.indexWhere((b) => b.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(clearDeletedAt: true);
    await _store.persistBrands();
  }

  @override
  int countEquipmentLinks(int brandId) =>
      _store.equipment
          .where((e) => e.brandId == brandId && e.deletedAt == null)
          .length;

  @override
  Future<int> deleteMany(List<int> ids) async {
    var removed = 0;
    for (final id in ids) {
      try {
        await hardDelete(id);
        removed++;
      } on ReferenceInUseException {
        // skip blocked rows during bulk delete
      }
    }
    return removed;
  }
}
