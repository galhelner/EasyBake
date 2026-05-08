import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user_preferences.dart';

class UserPreferencesStorageService {
  static const _kHealthyModeKey = 'preferences.healthyModeEnabled';

  Future<UserPreferences> restoreFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final healthyModeEnabled = prefs.getBool(_kHealthyModeKey) ?? true;

    return UserPreferences(
      healthyModeEnabled: healthyModeEnabled,
    );
  }

  Future<void> persistPreferences(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHealthyModeKey, preferences.healthyModeEnabled);
  }

  Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHealthyModeKey);
  }
}

final userPreferencesStorageServiceProvider =
    Provider<UserPreferencesStorageService>((ref) {
  return UserPreferencesStorageService();
});
