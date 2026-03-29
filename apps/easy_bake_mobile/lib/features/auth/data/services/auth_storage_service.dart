import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/auth_state.dart';

class AuthStorageService {
  static const _kAccessTokenKey = 'auth.accessToken';
  static const _kUserIdKey = 'auth.userId';
  static const _kEmailKey = 'auth.email';
  static const _kDisplayNameKey = 'auth.displayName';

  Future<AuthState> restoreFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccessTokenKey);

    if (token == null || token.isEmpty) {
      return const AuthState();
    }

    return AuthState(
      accessToken: token,
      userId: prefs.getString(_kUserIdKey),
      email: prefs.getString(_kEmailKey),
      displayName: prefs.getString(_kDisplayNameKey),
    );
  }

  Future<void> persistAuth(AuthState authState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessTokenKey, authState.accessToken ?? '');

    final userId = authState.userId;
    final email = authState.email;
    final displayName = authState.displayName;

    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_kUserIdKey, userId);
    } else {
      await prefs.remove(_kUserIdKey);
    }

    if (email != null && email.isNotEmpty) {
      await prefs.setString(_kEmailKey, email);
    } else {
      await prefs.remove(_kEmailKey);
    }

    if (displayName != null && displayName.isNotEmpty) {
      await prefs.setString(_kDisplayNameKey, displayName);
    } else {
      await prefs.remove(_kDisplayNameKey);
    }
  }

  Future<void> clearPersistedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessTokenKey);
    await prefs.remove(_kUserIdKey);
    await prefs.remove(_kEmailKey);
    await prefs.remove(_kDisplayNameKey);
  }
}

final authStorageServiceProvider = Provider<AuthStorageService>((ref) {
  return AuthStorageService();
});
