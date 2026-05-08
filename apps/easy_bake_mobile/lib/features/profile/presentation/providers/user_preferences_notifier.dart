import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/user_preferences_storage_service.dart';
import '../../domain/models/user_preferences.dart';

class UserPreferencesNotifier extends Notifier<UserPreferences> {
  @override
  UserPreferences build() => const UserPreferences();

  Future<void> toggleHealthyMode(bool enabled) async {
    state = state.copyWith(healthyModeEnabled: enabled);
    final storage = ref.read(userPreferencesStorageServiceProvider);
    await storage.persistPreferences(state);
  }

  Future<void> restoreFromStorage() async {
    final storage = ref.read(userPreferencesStorageServiceProvider);
    state = await storage.restoreFromStorage();
  }

  Future<void> clearPreferences() async {
    state = const UserPreferences();
    final storage = ref.read(userPreferencesStorageServiceProvider);
    await storage.clearPreferences();
  }
}

final userPreferencesNotifierProvider =
    NotifierProvider<UserPreferencesNotifier, UserPreferences>(
  UserPreferencesNotifier.new,
);

/// Provides whether healthy mode is currently enabled.
final healthyModeEnabledProvider = Provider<bool>((ref) {
  return ref.watch(userPreferencesNotifierProvider).healthyModeEnabled;
});
