import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/auth_storage_service.dart';
import '../../domain/models/auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void setAuth({
    required String accessToken,
    String? userId,
    String? email,
    String? displayName,
  }) {
    state = AuthState(
      userId: userId,
      email: email,
      displayName: displayName,
      accessToken: accessToken,
    );
    final storage = ref.read(authStorageServiceProvider);
    unawaited(storage.persistAuth(state));
  }

  void clear() {
    state = const AuthState();
    final storage = ref.read(authStorageServiceProvider);
    unawaited(storage.clearPersistedAuth());
  }

  Future<void> restoreFromStorage() async {
    final storage = ref.read(authStorageServiceProvider);
    state = await storage.restoreFromStorage();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Provides the current access token (or null) for attaching to requests.
final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).accessToken;
});
