import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_state.dart';

/// The base API client used for authenticated endpoints (recipes + auth).
///
/// By default this points to the recipe-service (port 4000).
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    // Switches IP automatically based on device.
    baseUrl: Platform.isAndroid ? 'http://10.0.2.2:4000' : 'http://localhost:4000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // Automatically attach `Authorization: Bearer <token>` when available.
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    final token = ref.read(authTokenProvider);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }));

  return dio;
});
