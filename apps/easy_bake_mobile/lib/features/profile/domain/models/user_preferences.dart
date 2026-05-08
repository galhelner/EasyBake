class UserPreferences {
  final bool healthyModeEnabled;

  const UserPreferences({
    this.healthyModeEnabled = true,
  });

  UserPreferences copyWith({
    bool? healthyModeEnabled,
  }) {
    return UserPreferences(
      healthyModeEnabled: healthyModeEnabled ?? this.healthyModeEnabled,
    );
  }

  @override
  String toString() => 'UserPreferences(healthyModeEnabled: $healthyModeEnabled)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          healthyModeEnabled == other.healthyModeEnabled;

  @override
  int get hashCode => healthyModeEnabled.hashCode;
}
