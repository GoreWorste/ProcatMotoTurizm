class NamedId {
  const NamedId({required this.id, required this.name});

  final int id;
  final String name;
}

const List<NamedId> equipmentCategories = [
  NamedId(id: 1, name: 'Палатки'),
  NamedId(id: 2, name: 'Велосипеды'),
  NamedId(id: 3, name: 'Мотоциклы'),
  NamedId(id: 4, name: 'Квадроциклы'),
  NamedId(id: 5, name: 'Водный транспорт'),
  NamedId(id: 6, name: 'Снегоходы'),
];

const List<NamedId> equipmentBrands = [
  NamedId(id: 1, name: 'Tramp'),
  NamedId(id: 2, name: 'Stels'),
  NamedId(id: 3, name: 'Yamaha'),
  NamedId(id: 4, name: 'Polaris'),
  NamedId(id: 5, name: 'Trek'),
  NamedId(id: 6, name: 'Sea-Doo'),
  NamedId(id: 7, name: 'Buran'),
];

const List<NamedId> equipmentTags = [
  NamedId(id: 1, name: 'зима'),
  NamedId(id: 2, name: 'лето'),
  NamedId(id: 3, name: 'для новичков'),
  NamedId(id: 4, name: 'экстрим'),
  NamedId(id: 5, name: 'водный'),
];

String categoryName(int id) =>
    equipmentCategories.firstWhere((c) => c.id == id, orElse: () => const NamedId(id: 0, name: '—')).name;

String brandName(int id) =>
    equipmentBrands.firstWhere((b) => b.id == id, orElse: () => const NamedId(id: 0, name: '—')).name;

String tagNames(List<int> ids) =>
    ids.map((id) => equipmentTags.firstWhere((t) => t.id == id, orElse: () => const NamedId(id: 0, name: '?')).name).join(', ');
