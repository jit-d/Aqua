class Achievement {
  final String id;
  final String name;
  final String description;
  final int target;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.target,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
  });

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
  }) =>
      Achievement(
        id: id,
        name: name,
        description: description,
        target: target,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        progress: progress ?? this.progress,
      );
}