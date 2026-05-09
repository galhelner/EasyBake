import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:easy_bake_mobile/core/network/api_client.dart';
import 'package:easy_bake_mobile/features/auth/presentation/providers/auth_notifier.dart';
import '../../data/services/user_preferences_storage_service.dart';
import '../../domain/models/user_preferences.dart';

class UserPreferencesNotifier extends Notifier<UserPreferences> {
  @override
  UserPreferences build() {
    // Listen for auth state changes and restore preferences for the new user
    ref.listen(authNotifierProvider, (previousAuth, nextAuth) {
      final previousUserId = previousAuth?.userId;
      final nextUserId = nextAuth.userId;

      // If user changed, clear current state and restore new user's preferences
      if (previousUserId != nextUserId) {
        if (nextUserId != null && nextUserId.isNotEmpty) {
          // New user logged in, restore their preferences
          unawaited(_restoreForUser(nextUserId));
        } else {
          // User logged out
          state = const UserPreferences();
        }
      }
    });

    return const UserPreferences();
  }

  Future<void> _restoreForUser(String userId) async {
    final storage = ref.read(userPreferencesStorageServiceProvider);
    state = await storage.restoreFromStorage(userId: userId);
  }

  Future<void> toggleHealthyMode(bool enabled) async {
    state = state.copyWith(healthyModeEnabled: enabled);
    final storage = ref.read(userPreferencesStorageServiceProvider);
    final authState = ref.read(authNotifierProvider);
    final userId = authState.userId;
    if (userId != null) {
      await storage.persistPreferences(state, userId: userId);
    }
  }

  Future<void> updateChatDisplayName(String? displayName) async {
    // Update local UI state temporarily for optimistic feedback
    state = state.copyWith(chatDisplayName: displayName);
    
    // Persist to chat-service so other clients see the change and it's stored in database
    try {
      final authState = ref.read(authNotifierProvider);
      final token = authState.accessToken;
      if (token == null || token.isEmpty) return;

      final chatBase = ref.read(chatServiceBaseUrlProvider);
      final dio = Dio(BaseOptions(baseUrl: chatBase, headers: {
        'Authorization': 'Bearer $token',
      }));

      await dio.patch('/profile', data: {'displayName': displayName});
      
      // After successful save, update auth state displayName
      ref.read(authNotifierProvider.notifier).setAuth(
        accessToken: authState.accessToken ?? '',
        userId: authState.userId,
        email: authState.email,
        fullName: authState.fullName,
        displayName: displayName,
      );
    } catch (e) {
      // On error, reset UI state since server save failed
      final storage = ref.read(userPreferencesStorageServiceProvider);
      final authState = ref.read(authNotifierProvider);
      final userId = authState.userId;
      if (userId != null) {
        state = await storage.restoreFromStorage(userId: userId);
      }
    }
  }

  Future<void> restoreFromStorage() async {
    final storage = ref.read(userPreferencesStorageServiceProvider);
    final authState = ref.read(authNotifierProvider);
    final userId = authState.userId;
    state = await storage.restoreFromStorage(userId: userId);
  }

  Future<void> clearPreferences() async {
    state = const UserPreferences();
    final storage = ref.read(userPreferencesStorageServiceProvider);
    final authState = ref.read(authNotifierProvider);
    final userId = authState.userId;
    await storage.clearPreferences(userId: userId);
  }
}

final userPreferencesNotifierProvider =
    NotifierProvider<UserPreferencesNotifier, UserPreferences>(
  UserPreferencesNotifier.new,
);

/// Provides whether healthy mode is currently enabled.
final healthyModeEnabledProvider = Provider<bool>((ref) {
  return ref.watch(userPreferencesNotifierProvider).healthyModeEnabled;
});
