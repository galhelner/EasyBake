import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple auth state used throughout the app.
class AuthState {
  final String? userId;
  final String? email;
  final String? accessToken;

  const AuthState({this.userId, this.email, this.accessToken});

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;
}

class AuthNotifier extends Notifier<AuthState> {
  static const _kAccessTokenKey = 'auth.accessToken';
  static const _kUserIdKey = 'auth.userId';
  static const _kEmailKey = 'auth.email';

  @override
  AuthState build() => const AuthState();

  void setAuth({required String accessToken, String? userId, String? email}) {
    state = AuthState(userId: userId, email: email, accessToken: accessToken);
    unawaited(_persistAuth(state));
  }

  void clear() {
    state = const AuthState();
    unawaited(_clearPersistedAuth());
  }

  Future<void> restoreFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccessTokenKey);

    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }

    state = AuthState(
      accessToken: token,
      userId: prefs.getString(_kUserIdKey),
      email: prefs.getString(_kEmailKey),
    );
  }

  Future<void> _persistAuth(AuthState authState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessTokenKey, authState.accessToken ?? '');

    final userId = authState.userId;
    final email = authState.email;

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
  }

  Future<void> _clearPersistedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessTokenKey);
    await prefs.remove(_kUserIdKey);
    await prefs.remove(_kEmailKey);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Provides the current access token (or null) for attaching to requests.
final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).accessToken;
});
