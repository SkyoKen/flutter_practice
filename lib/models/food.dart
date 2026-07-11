class Food {
  final int id;
  final String nameKey;
  final String descriptionKey;
  final int unlockLevel;
  final double baseRewardCoins;
  final Set<String> tags;

  const Food({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.unlockLevel,
    required this.baseRewardCoins,
    required this.tags,
  });

  // Food IDs are stable save-data identities across the game.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Food && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
