import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/models/auth_state.dart';

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  Future<bool> emailExists({required String email}) async {
    final response = await _dio.post(
      '/auth/email-exists',
      data: {'email': email.trim()},
    );

    final json = response.data as Map<String, dynamic>;
    return json['exists'] == true;
  }

  Future<AuthState> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

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
      displayName: user?['fullName'] as String?,
    );
  }

  Future<AuthState> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'fullName': fullName, 'email': email, 'password': password},
    );

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
      displayName: user?['fullName'] as String?,
    );
  }
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.read(dioProvider));
});
