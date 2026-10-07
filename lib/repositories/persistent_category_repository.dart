import '../core/repository_exceptions.dart';
import 'package:dio/dio.dart';

import '../models/category.dart';
import '../models/named_entity_query.dart';
import '../models/page_result.dart';
import 'app_data_store.dart';
import 'category_repository.dart';
import 'named_entity_find.dart';

class PersistentCategoryRepository implements CategoryRepository {
  PersistentCategoryRepository(this._store);

  final AppDataStore _store;

  List<Category> get _items => _store.categories;

  @override
  Future<PageResult<Category>> find(
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
      nameOf: (c) => c.name,
      deletedAtOf: (c) => c.deletedAt,
    );
  }

  @override
  Future<List<Category>> findAll({bool includeDeleted = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    var list = List<Category>.from(_items);
    if (!includeDeleted) {
      list = list.where((c) => c.deletedAt == null).toList();
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<Category?> findById(int id) async {
    try {
      return _items.firstWhere((c) => c.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Category> create(Category item) async {
    final created = item.copyWith(id: _store.categoryNextId++);
    _items.add(created);
    await _store.persistCategories();
    return created;
  }

  @override
  Future<Category> update(Category item) async {
    final index = _items.indexWhere((c) => c.id == item.id);
    if (index < 0) throw StateError('Category not found');
    _items[index] = item;
    await _store.persistCategories();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
    await _store.persistCategories();
  }

  @override
  Future<void> hardDelete(int id) async {
    final count = countEquipmentLinks(id);
    if (count > 0) {
      throw ReferenceInUseException(
        'Нельзя удалить категорию: связано единиц оборудования — $count',
        count: count,
      );
    }
    _items.removeWhere((c) => c.id == id);
    await _store.persistCategories();
  }

  @override
  Future<void> restore(int id) async {
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(clearDeletedAt: true);
    await _store.persistCategories();
  }

  @override
  int countEquipmentLinks(int categoryId) =>
      _store.equipment
          .where((e) => e.categoryId == categoryId && e.deletedAt == null)
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
