import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple auth state used throughout the app.
class AuthState {
  final String? userId;
  final String? email;
  final String? accessToken;

  const AuthState({this.userId, this.email, this.accessToken});

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void setAuth({required String accessToken, String? userId, String? email}) {
    state = AuthState(userId: userId, email: email, accessToken: accessToken);
  }

  void clear() {
    state = const AuthState();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Provides the current access token (or null) for attaching to requests.
final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).accessToken;
});
