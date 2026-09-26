class Client {
  const Client({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.registeredAt,
    this.deletedAt,
  });

  final int id;
  final String fullName;
  final String phone;
  final String city;
  final DateTime registeredAt;
  final DateTime? deletedAt;

  Client copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? city,
    DateTime? registeredAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      registeredAt: registeredAt ?? this.registeredAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
