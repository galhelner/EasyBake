/// A simple auth state used throughout the app.
class AuthState {
  final String? userId;
  final String? email;
  final String? displayName;
  final String? accessToken;

  const AuthState({
    this.userId,
    this.email,
    this.displayName,
    this.accessToken,
  });

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;
}
