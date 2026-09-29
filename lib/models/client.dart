import 'rental_card.dart';

class Client {
  const Client({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.registeredAt,
    required this.rentalCard,
    this.deletedAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final DateTime registeredAt;
  final RentalCard rentalCard;
  final DateTime? deletedAt;

  Client copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? city,
    DateTime? registeredAt,
    RentalCard? rentalCard,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      registeredAt: registeredAt ?? this.registeredAt,
      rentalCard: rentalCard ?? this.rentalCard,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'city': city,
        'registeredAt': registeredAt.toIso8601String(),
        'rentalCard': rentalCard.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as int? ?? 0,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ??
            'client${json['id'] as int? ?? 0}@example.local',
        phone: json['phone'] as String? ?? '',
        city: json['city'] as String? ?? '',
        registeredAt: json['registeredAt'] == null
            ? DateTime.now()
            : DateTime.parse(json['registeredAt'] as String),
        rentalCard: RentalCard.fromJson(
          json['rentalCard'] as Map<String, dynamic>?,
        ),
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
