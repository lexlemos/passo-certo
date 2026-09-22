class NavigationPreferences {
  final bool avoidStairs;
  final bool requiresTactilePaving;
  final bool voiceNavigation;

  const NavigationPreferences({
    required this.avoidStairs,
    required this.requiresTactilePaving,
    required this.voiceNavigation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationPreferences &&
          runtimeType == other.runtimeType &&
          avoidStairs == other.avoidStairs &&
          requiresTactilePaving == other.requiresTactilePaving &&
          voiceNavigation == other.voiceNavigation;

  @override
  int get hashCode =>
      avoidStairs.hashCode ^
      requiresTactilePaving.hashCode ^
      voiceNavigation.hashCode;
}

abstract class NavigationPreferencesReader {
  NavigationPreferences get current;
}
