class Brand {
  const Brand({
    required this.id,
    required this.name,
    this.deletedAt,
  });

  final int id;
  final String name;
  final DateTime? deletedAt;

  Brand copyWith({
    int? id,
    String? name,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
