import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'auth_state.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<AuthState> login({required String email, required String password}) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final json = response.data as Map<String, dynamic>;
    final accessToken = json['access_token'] as String?;
    final user = json['user'] as Map<String, dynamic>?;

    if (accessToken == null) {
      throw Exception('Login did not return access token');
    }

    return AuthState(
      accessToken: accessToken,
      userId: user?['id'] as String?,
      email: user?['email'] as String?,
    );
  }

  Future<AuthState> register({required String email, required String password}) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
    });

    final json = response.data as Map<String, dynamic>;
    final accessToken = json['access_token'] as String?;
    final user = json['user'] as Map<String, dynamic>?;

    if (accessToken == null) {
      throw Exception('Register did not return access token');
    }

    return AuthState(
      accessToken: accessToken,
      userId: user?['id'] as String?,
      email: user?['email'] as String?,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});
