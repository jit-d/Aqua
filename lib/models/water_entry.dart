class WaterEntry {
  final int? id;
  final int amountMl;
  final String drinkType;
  final DateTime createdAt;
  final String localDate;

  WaterEntry({
    this.id,
    required this.amountMl,
    required this.drinkType,
    required this.createdAt,
    required this.localDate,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'amount_ml': amountMl,
        'drink_type': drinkType,
        'created_at': createdAt.toIso8601String(),
        'local_date': localDate,
      };

  factory WaterEntry.fromMap(Map<String, dynamic> m) => WaterEntry(
        id: m['id'] as int?,
        amountMl: m['amount_ml'] as int,
        drinkType: m['drink_type'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        localDate: m['local_date'] as String,
      );
}