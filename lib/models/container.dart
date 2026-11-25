class WaterContainer {
  final int? id;
  final String name;
  final int volumeMl;
  final String icon;

  WaterContainer({
    this.id,
    required this.name,
    required this.volumeMl,
    this.icon = 'local_drink',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'volume_ml': volumeMl,
        'icon': icon,
      };

  factory WaterContainer.fromMap(Map<String, dynamic> m) => WaterContainer(
        id: m['id'] as int?,
        name: m['name'] as String,
        volumeMl: m['volume_ml'] as int,
        icon: m['icon'] as String? ?? 'local_drink',
      );
}
