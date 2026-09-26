import '../models/client.dart';
import '../models/client_query.dart';
import '../models/page_result.dart';
import 'client_repository.dart';

class InMemoryClientRepository implements ClientRepository {
  InMemoryClientRepository() : _items = List<Client>.from(_seedData);

  final List<Client> _items;
  int _nextId = 100;

  static final List<Client> _seedData = [
    Client(id: 1, fullName: 'Иванов Алексей Петрович', phone: '+7 (912) 345-67-01', city: 'Екатеринбург', registeredAt: DateTime(2022, 3, 12)),
    Client(id: 2, fullName: 'Петрова Мария Сергеевна', phone: '+7 (922) 111-22-33', city: 'Челябинск', registeredAt: DateTime(2021, 11, 5)),
    Client(id: 3, fullName: 'Сидоров Дмитрий Игоревич', phone: '+7 (343) 555-44-22', city: 'Екатеринбург', registeredAt: DateTime(2023, 1, 20)),
    Client(id: 4, fullName: 'Козлова Анна Викторовна', phone: '+7 (912) 777-88-99', city: 'Пермь', registeredAt: DateTime(2020, 7, 8)),
    Client(id: 5, fullName: 'Новиков Павел Олегович', phone: '+7 (351) 200-30-40', city: 'Челябинск', registeredAt: DateTime(2024, 2, 14)),
    Client(id: 6, fullName: 'Морозова Елена Андреевна', phone: '+7 (912) 900-11-22', city: 'Тюмень', registeredAt: DateTime(2022, 9, 30)),
    Client(id: 7, fullName: 'Волков Артём Николаевич', phone: '+7 (922) 333-44-55', city: 'Пермь', registeredAt: DateTime(2023, 6, 18)),
    Client(id: 8, fullName: 'Смирнова Ольга Дмитриевна', phone: '+7 (343) 666-77-88', city: 'Екатеринбург', registeredAt: DateTime(2021, 4, 2)),
    Client(id: 9, fullName: 'Фёдоров Кирилл Александрович', phone: '+7 (912) 123-45-67', city: 'Тюмень', registeredAt: DateTime(2024, 8, 1)),
  ];

  @override
  Future<PageResult<Client>> find(ClientQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

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
                c.phone.replaceAll(RegExp(r'\D'), '').contains(
                      search.replaceAll(RegExp(r'\D'), ''),
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
    final created = item.copyWith(id: _nextId++);
    _items.add(created);
    return created;
  }

  @override
  Future<Client> update(Client item) async {
    final index = _items.indexWhere((c) => c.id == item.id);
    if (index < 0) {
      throw StateError('Client not found');
    }
    _items[index] = item;
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(clearDeletedAt: true);
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
    return removed;
  }
}
