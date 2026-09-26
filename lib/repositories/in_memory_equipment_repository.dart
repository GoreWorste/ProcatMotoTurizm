import '../models/equipment.dart';
import '../models/equipment_query.dart';
import '../models/page_result.dart';
import 'equipment_repository.dart';

class InMemoryEquipmentRepository implements EquipmentRepository {
  InMemoryEquipmentRepository() : _items = List<Equipment>.from(_seedData);

  final List<Equipment> _items;
  int _nextId = 100;

  static final List<Equipment> _seedData = [
    Equipment(id: 1, name: 'Палатка Tramp Lite 2', inventoryNumber: 'EQ-1001', categoryId: 1, brandId: 1, purchaseYear: 2021, dailyRate: 450, condition: 'хорошее', unitsTotal: 8, unitsAvailable: 5, tagIds: [2, 3]),
    Equipment(id: 2, name: 'Палатка Tramp Alpine 4', inventoryNumber: 'EQ-1002', categoryId: 1, brandId: 1, purchaseYear: 2020, dailyRate: 780, condition: 'новое', unitsTotal: 4, unitsAvailable: 4, tagIds: [1, 2]),
    Equipment(id: 3, name: 'Велосипед Trek Marlin 7', inventoryNumber: 'EQ-2001', categoryId: 2, brandId: 5, purchaseYear: 2022, dailyRate: 600, condition: 'хорошее', unitsTotal: 6, unitsAvailable: 3, tagIds: [2, 3]),
    Equipment(id: 4, name: 'Велосипед Stels Navigator 610', inventoryNumber: 'EQ-2002', categoryId: 2, brandId: 2, purchaseYear: 2019, dailyRate: 350, condition: 'требует обслуживания', unitsTotal: 10, unitsAvailable: 7, tagIds: [2, 3]),
    Equipment(id: 5, name: 'Мотоцикл Yamaha XT660R', inventoryNumber: 'EQ-3001', categoryId: 3, brandId: 3, purchaseYear: 2018, dailyRate: 3200, condition: 'хорошее', unitsTotal: 3, unitsAvailable: 1, tagIds: [2, 4]),
    Equipment(id: 6, name: 'Мотоцикл Stels Flame 200', inventoryNumber: 'EQ-3002', categoryId: 3, brandId: 2, purchaseYear: 2023, dailyRate: 1800, condition: 'новое', unitsTotal: 5, unitsAvailable: 4, tagIds: [2, 3, 4]),
    Equipment(id: 7, name: 'Квадроцикл Stels ATV 500', inventoryNumber: 'EQ-4001', categoryId: 4, brandId: 2, purchaseYear: 2020, dailyRate: 4500, condition: 'хорошее', unitsTotal: 4, unitsAvailable: 2, tagIds: [2, 4]),
    Equipment(id: 8, name: 'Квадроцикл Polaris Sportsman 570', inventoryNumber: 'EQ-4002', categoryId: 4, brandId: 4, purchaseYear: 2021, dailyRate: 5200, condition: 'новое', unitsTotal: 2, unitsAvailable: 2, tagIds: [1, 2, 4]),
    Equipment(id: 9, name: 'Гидроцикл Sea-Doo Spark Trixx', inventoryNumber: 'EQ-5001', categoryId: 5, brandId: 6, purchaseYear: 2022, dailyRate: 6800, condition: 'новое', unitsTotal: 3, unitsAvailable: 1, tagIds: [2, 5]),
    Equipment(id: 10, name: 'Каяк двухместный Tramp', inventoryNumber: 'EQ-5002', categoryId: 5, brandId: 1, purchaseYear: 2019, dailyRate: 900, condition: 'хорошее', unitsTotal: 12, unitsAvailable: 9, tagIds: [2, 5, 3]),
    Equipment(id: 11, name: 'Снегоход Buran LE', inventoryNumber: 'EQ-6001', categoryId: 6, brandId: 7, purchaseYear: 2017, dailyRate: 4100, condition: 'требует обслуживания', unitsTotal: 2, unitsAvailable: 0, tagIds: [1, 3]),
    Equipment(id: 12, name: 'Снегоход Yamaha VK540', inventoryNumber: 'EQ-6002', categoryId: 6, brandId: 3, purchaseYear: 2020, dailyRate: 5500, condition: 'хорошее', unitsTotal: 3, unitsAvailable: 2, tagIds: [1, 4]),
    Equipment(id: 13, name: 'Палатка Tramp Wind 3', inventoryNumber: 'EQ-1003', categoryId: 1, brandId: 1, purchaseYear: 2024, dailyRate: 520, condition: 'новое', unitsTotal: 6, unitsAvailable: 6, tagIds: [2]),
    Equipment(id: 14, name: 'Велосипед Trek FX 3', inventoryNumber: 'EQ-2003', categoryId: 2, brandId: 5, purchaseYear: 2023, dailyRate: 550, condition: 'новое', unitsTotal: 4, unitsAvailable: 2, tagIds: [2, 3]),
    Equipment(id: 15, name: 'Мотоцикл Yamaha MT-07', inventoryNumber: 'EQ-3003', categoryId: 3, brandId: 3, purchaseYear: 2022, dailyRate: 4800, condition: 'хорошее', unitsTotal: 2, unitsAvailable: 1, tagIds: [2, 4]),
    Equipment(id: 16, name: 'Квадроцикл Stels Guepard 800', inventoryNumber: 'EQ-4003', categoryId: 4, brandId: 2, purchaseYear: 2019, dailyRate: 3900, condition: 'хорошее', unitsTotal: 3, unitsAvailable: 1, tagIds: [2, 4]),
    Equipment(id: 17, name: 'SUP-доска Sea-Doo', inventoryNumber: 'EQ-5003', categoryId: 5, brandId: 6, purchaseYear: 2021, dailyRate: 1200, condition: 'хорошее', unitsTotal: 8, unitsAvailable: 6, tagIds: [2, 5]),
    Equipment(id: 18, name: 'Снегоход Buran 4T', inventoryNumber: 'EQ-6003', categoryId: 6, brandId: 7, purchaseYear: 2023, dailyRate: 4700, condition: 'новое', unitsTotal: 2, unitsAvailable: 2, tagIds: [1]),
    Equipment(id: 19, name: 'Палатка Tramp Family 6', inventoryNumber: 'EQ-1004', categoryId: 1, brandId: 1, purchaseYear: 2018, dailyRate: 1100, condition: 'требует обслуживания', unitsTotal: 3, unitsAvailable: 1, tagIds: [2, 3]),
    Equipment(id: 20, name: 'Велосипед Stels Flash 2.0', inventoryNumber: 'EQ-2004', categoryId: 2, brandId: 2, purchaseYear: 2024, dailyRate: 420, condition: 'новое', unitsTotal: 7, unitsAvailable: 5, tagIds: [2, 3, 4]),
    Equipment(id: 21, name: 'Мотоцикл Stels Delta 200', inventoryNumber: 'EQ-3004', categoryId: 3, brandId: 2, purchaseYear: 2020, dailyRate: 1500, condition: 'хорошее', unitsTotal: 4, unitsAvailable: 3, tagIds: [3]),
    Equipment(id: 22, name: 'Катамаран Sea-Doo Switch', inventoryNumber: 'EQ-5004', categoryId: 5, brandId: 6, purchaseYear: 2024, dailyRate: 8900, condition: 'новое', unitsTotal: 1, unitsAvailable: 1, tagIds: [2, 5, 4]),
  ];

  @override
  Future<PageResult<Equipment>> find(EquipmentQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    var list = List<Equipment>.from(_items);

    if (!query.includeDeleted) {
      list = list.where((e) => e.deletedAt == null).toList();
    }

    final search = query.search.trim().toLowerCase();
    if (search.isNotEmpty) {
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
    final created = item.copyWith(id: _nextId++);
    _items.add(created);
    return created;
  }

  @override
  Future<Equipment> update(Equipment item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index < 0) {
      throw StateError('Equipment not found');
    }
    _items[index] = item;
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(clearDeletedAt: true);
  }

  // ВАРИАНТ С ОШИБКОЙ (для отчёта):
  // @override
  // Future<int> deleteMany(List<int> ids) async {
  //   var removed = 0;
  //   for (var i = 0; i < ids.length; i++) {
  //     final index = _items.indexWhere((e) => e.id == ids[i]);
  //     if (index > 0) {
  //       _items.removeAt(index);
  //       removed++;
  //     }
  //   }
  //   return removed;
  // }
  // Ошибка: условие `index > 0` пропускает элемент с индексом 0 в списке,
  // поэтому запись в начале коллекции никогда не удалялась при массовом удалении.

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
    return removed;
  }
}
