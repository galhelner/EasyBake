import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';

const _cloudRecipeServiceBaseUrl =
  'https://easybake-recipe-service-h7dtcrbhfbdthmcz.israelcentral-01.azurewebsites.net';
const _localRecipeServiceBaseUrlDefault = 'http://localhost:4000';
const _localRecipeServiceBaseUrlAndroidEmulator = 'http://10.0.2.2:4000';
const _connectTimeout = Duration(seconds: 30);
const _sendTimeout = Duration(seconds: 30);
const _receiveTimeout = Duration(seconds: 90);

// Toggle with --dart-define=DEV_MODE=true to target local recipe-service.
const _devMode = bool.fromEnvironment('DEV_MODE', defaultValue: false);

// Optional override for local testing on physical devices or custom host IP.
// Example: --dart-define=LOCAL_API_BASE_URL=http://192.168.1.20:4000
const _localApiBaseUrlOverride = String.fromEnvironment(
  'LOCAL_API_BASE_URL',
  defaultValue: '',
);

// Inject via --dart-define=INTERNAL_APP_SECRET=... for non-hardcoded secret management.
const _internalAppSecret = String.fromEnvironment(
  'INTERNAL_APP_SECRET',
  defaultValue: '',
);

/// The base API client used for authenticated endpoints (recipes + auth).
///
/// By default this points to the hosted recipe-service endpoint.
String _resolveLocalBaseUrl() {
  final override = _localApiBaseUrlOverride.trim();
  if (override.isNotEmpty) {
    return override;
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return _localRecipeServiceBaseUrlAndroidEmulator;
  }

  return _localRecipeServiceBaseUrlDefault;
}

final dioProvider = Provider<Dio>((ref) {
  final resolvedBaseUrl = _devMode ? _resolveLocalBaseUrl() : _cloudRecipeServiceBaseUrl;
  debugPrint('[EasyBake] API baseUrl: $resolvedBaseUrl (DEV_MODE=$_devMode)');

  final dio = Dio(
    BaseOptions(
      baseUrl: resolvedBaseUrl,
      connectTimeout: _connectTimeout,
      sendTimeout: _sendTimeout,
      receiveTimeout: _receiveTimeout,
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
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          ref.read(authNotifierProvider.notifier).clear();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
