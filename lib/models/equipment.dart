class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.inventoryNumber,
    required this.categoryId,
    required this.brandId,
    required this.purchaseYear,
    required this.dailyRate,
    required this.condition,
    required this.unitsTotal,
    required this.unitsAvailable,
    required this.tagIds,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String inventoryNumber;
  final int categoryId;
  final int brandId;
  final int purchaseYear;
  final double dailyRate;
  final String condition;
  final int unitsTotal;
  final int unitsAvailable;
  final List<int> tagIds;
  final DateTime? deletedAt;

  Equipment copyWith({
    int? id,
    String? name,
    String? inventoryNumber,
    int? categoryId,
    int? brandId,
    int? purchaseYear,
    double? dailyRate,
    String? condition,
    int? unitsTotal,
    int? unitsAvailable,
    List<int>? tagIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      inventoryNumber: inventoryNumber ?? this.inventoryNumber,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      purchaseYear: purchaseYear ?? this.purchaseYear,
      dailyRate: dailyRate ?? this.dailyRate,
      condition: condition ?? this.condition,
      unitsTotal: unitsTotal ?? this.unitsTotal,
      unitsAvailable: unitsAvailable ?? this.unitsAvailable,
      tagIds: tagIds ?? this.tagIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'inventoryNumber': inventoryNumber,
        'categoryId': categoryId,
        'brandId': brandId,
        'purchaseYear': purchaseYear,
        'dailyRate': dailyRate,
        'condition': condition,
        'unitsTotal': unitsTotal,
        'unitsAvailable': unitsAvailable,
        'tagIds': tagIds,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        inventoryNumber: json['inventoryNumber'] as String? ?? '',
        categoryId: json['categoryId'] as int? ?? 0,
        brandId: json['brandId'] as int? ?? 0,
        purchaseYear: json['purchaseYear'] as int? ?? 0,
        dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0,
        condition: json['condition'] as String? ?? '',
        unitsTotal: json['unitsTotal'] as int? ?? 0,
        unitsAvailable: json['unitsAvailable'] as int? ?? 0,
        tagIds: (json['tagIds'] as List?)?.cast<int>() ?? const [],
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
