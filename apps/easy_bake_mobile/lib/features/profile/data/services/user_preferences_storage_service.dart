import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user_preferences.dart';

class UserPreferencesStorageService {
  static const _kHealthyModeKeyPrefix = 'preferences.healthyModeEnabled';

  String _getHealthyModeKey(String userId) => '$_kHealthyModeKeyPrefix.$userId';

  Future<UserPreferences> restoreFromStorage({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // If no userId provided, use legacy key (for backward compatibility during first load)
    if (userId == null) {
      final healthyModeEnabled = prefs.getBool(_kHealthyModeKeyPrefix) ?? true;
      return UserPreferences(
        healthyModeEnabled: healthyModeEnabled,
        chatDisplayName: null, // displayName now comes from server/auth state
      );
    }
    
    final healthyModeKey = _getHealthyModeKey(userId);
    final healthyModeEnabled = prefs.getBool(healthyModeKey) ?? true;

    return UserPreferences(
      healthyModeEnabled: healthyModeEnabled,
      chatDisplayName: null, // displayName now comes from server/auth state
    );
  }

  Future<void> persistPreferences(UserPreferences preferences, {required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final healthyModeKey = _getHealthyModeKey(userId);
    
    // Only persist healthyMode; displayName is persisted to the server via API
    await prefs.setBool(healthyModeKey, preferences.healthyModeEnabled);
  }

  Future<void> clearPreferences({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (userId == null) {
      // Clear legacy key
      await prefs.remove(_kHealthyModeKeyPrefix);
    } else {
      final healthyModeKey = _getHealthyModeKey(userId);
      await prefs.remove(healthyModeKey);
    }
  }
}

final userPreferencesStorageServiceProvider =
    Provider<UserPreferencesStorageService>((ref) {
  return UserPreferencesStorageService();
});
