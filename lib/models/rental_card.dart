class RentalCard {
  const RentalCard({
    required this.number,
    required this.issuedAt,
  });

  final String number;
  final DateTime issuedAt;

  RentalCard copyWith({String? number, DateTime? issuedAt}) {
    return RentalCard(
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'issuedAt': issuedAt.toIso8601String(),
      };

  factory RentalCard.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return RentalCard(
        number: '',
        issuedAt: DateTime.now(),
      );
    }
    return RentalCard(
      number: json['number'] as String? ?? '',
      issuedAt: json['issuedAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['issuedAt'] as String),
    );
  }
}
