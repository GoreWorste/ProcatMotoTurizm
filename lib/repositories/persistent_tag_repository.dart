import '../models/named_entity_query.dart';
import '../models/page_result.dart';
import '../models/tag.dart';
import 'app_data_store.dart';
import 'named_entity_find.dart';
import 'tag_repository.dart';

class PersistentTagRepository implements TagRepository {
  PersistentTagRepository(this._store);

  final AppDataStore _store;

  List<Tag> get _items => _store.tags;

  @override
  Future<PageResult<Tag>> find(NamedEntityQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (query.search.trim() == '__error__') {
      throw StateError('Симуляция ошибки загрузки');
    }
    return findNamedPage(
      source: _items,
      query: query,
      nameOf: (t) => t.name,
      deletedAtOf: (t) => t.deletedAt,
    );
  }

  @override
  Future<List<Tag>> findAll({bool includeDeleted = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    var list = List<Tag>.from(_items);
    if (!includeDeleted) {
      list = list.where((t) => t.deletedAt == null).toList();
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<Tag?> findById(int id) async {
    try {
      return _items.firstWhere((t) => t.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Tag> create(Tag item) async {
    final created = item.copyWith(id: _store.tagNextId++);
    _items.add(created);
    await _store.persistTags();
    return created;
  }

  @override
  Future<Tag> update(Tag item) async {
    final index = _items.indexWhere((t) => t.id == item.id);
    if (index < 0) throw StateError('Tag not found');
    _items[index] = item;
    await _store.persistTags();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _items.indexWhere((t) => t.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
    await _store.persistTags();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((t) => t.id == id);
    await _store.persistTags();
  }

  @override
  Future<void> restore(int id) async {
    final index = _items.indexWhere((t) => t.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(clearDeletedAt: true);
    await _store.persistTags();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var removed = 0;
    for (final id in ids) {
      final index = _items.indexWhere((t) => t.id == id);
      if (index >= 0) {
        _items.removeAt(index);
        removed++;
      }
    }
    if (removed > 0) {
      await _store.persistTags();
    }
    return removed;
  }
}
