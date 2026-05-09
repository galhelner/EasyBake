class UserPreferences {
  final bool healthyModeEnabled;
  final String? chatDisplayName;

  const UserPreferences({
    this.healthyModeEnabled = true,
    this.chatDisplayName,
  });

  UserPreferences copyWith({
    bool? healthyModeEnabled,
    String? chatDisplayName,
  }) {
    return UserPreferences(
      healthyModeEnabled: healthyModeEnabled ?? this.healthyModeEnabled,
      chatDisplayName: chatDisplayName ?? this.chatDisplayName,
    );
  }

  @override
  String toString() => 'UserPreferences(healthyModeEnabled: $healthyModeEnabled, chatDisplayName: $chatDisplayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          healthyModeEnabled == other.healthyModeEnabled &&
          chatDisplayName == other.chatDisplayName;

  @override
  int get hashCode => Object.hash(healthyModeEnabled, chatDisplayName);
}
