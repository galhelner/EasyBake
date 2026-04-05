import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';

const _cloudRecipeServiceBaseUrl =
  'https://easybake-recipe-service-h7dtcrbhfbdthmcz.israelcentral-01.azurewebsites.net';

// Inject via --dart-define=INTERNAL_APP_SECRET=... for non-hardcoded secret management.
const _internalAppSecret = String.fromEnvironment(
  'INTERNAL_APP_SECRET',
  defaultValue: '',
);

/// The base API client used for authenticated endpoints (recipes + auth).
///
/// By default this points to the hosted recipe-service endpoint.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // Use the cloud endpoint for all devices.
      baseUrl: _cloudRecipeServiceBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'X-App-Secret': _internalAppSecret,
      },
    ),
  );

  // Add interceptors - this code runs once per provider lifecycle

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authTokenProvider);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          ref.read(authNotifierProvider.notifier).clear();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
