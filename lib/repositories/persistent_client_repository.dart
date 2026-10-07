import 'package:dio/dio.dart';

import '../models/client.dart';
import '../models/client_query.dart';
import '../models/page_result.dart';
import 'app_data_store.dart';
import 'client_repository.dart';

class PersistentClientRepository implements ClientRepository {
  PersistentClientRepository(this._store);

  final AppDataStore _store;

  List<Client> get _items => _store.clients;

  static String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'\D'), '');

  @override
  Future<PageResult<Client>> find(
    ClientQuery query, {
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (query.search.trim() == '__error__') {
      throw StateError('Симуляция ошибки загрузки (учебный скриншот)');
    }

    var list = List<Client>.from(_items);

    if (!query.includeDeleted) {
      list = list.where((c) => c.deletedAt == null).toList();
    }

    final search = query.search.trim().toLowerCase();
    if (search.isNotEmpty) {
      list = list
          .where(
            (c) =>
                c.fullName.toLowerCase().contains(search) ||
                c.email.toLowerCase().contains(search) ||
                _normalizePhone(c.phone).contains(
                      _normalizePhone(search),
                    ) ||
                c.phone.toLowerCase().contains(search),
          )
          .toList();
    }

    if (query.city != null && query.city!.isNotEmpty) {
      list = list.where((c) => c.city == query.city).toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (query.sortField) {
        case 'phone':
          cmp = a.phone.compareTo(b.phone);
        case 'email':
          cmp = a.email.compareTo(b.email);
        case 'city':
          cmp = a.city.compareTo(b.city);
        case 'registeredAt':
          cmp = a.registeredAt.compareTo(b.registeredAt);
        case 'fullName':
        default:
          cmp = a.fullName.compareTo(b.fullName);
      }
      return query.sortAscending ? cmp : -cmp;
    });

    final total = list.length;
    final page = query.page < 1 ? 1 : query.page;
    final size = query.size < 1 ? 10 : query.size;
    final start = (page - 1) * size;
    final end = start + size;
    final to = end > total ? total : end;
    final pageItems = start >= total ? <Client>[] : list.sublist(start, to);

    return PageResult<Client>(
      items: pageItems,
      page: page,
      size: size,
      total: total,
    );
  }

  @override
  Future<Client?> findById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      return _items.firstWhere((c) => c.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Client> create(Client item) async {
    final created = item.copyWith(id: _store.clientNextId++);
    _items.add(created);
    await _store.persistClients();
    return created;
  }

  @override
  Future<Client> update(Client item) async {
    final index = _items.indexWhere((c) => c.id == item.id);
    if (index < 0) {
      throw StateError('Client not found');
    }
    _items[index] = item;
    await _store.persistClients();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
    await _store.persistClients();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((c) => c.id == id);
    await _store.persistClients();
  }

  @override
  Future<void> restore(int id) async {
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(clearDeletedAt: true);
    await _store.persistClients();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var removed = 0;
    for (final id in ids) {
      final index = _items.indexWhere((c) => c.id == id);
      if (index >= 0) {
        _items.removeAt(index);
        removed++;
      }
    }
    if (removed > 0) {
      await _store.persistClients();
    }
    return removed;
  }

  @override
  bool isPhoneTaken(String phone, {int? exceptId}) {
    final normalized = _normalizePhone(phone);
    return _items.any(
      (c) => _normalizePhone(c.phone) == normalized && c.id != exceptId,
    );
  }

  @override
  bool isEmailTaken(String email, {int? exceptId}) {
    final normalized = email.trim().toLowerCase();
    return _items.any(
      (c) => c.email.trim().toLowerCase() == normalized && c.id != exceptId,
    );
  }
}
