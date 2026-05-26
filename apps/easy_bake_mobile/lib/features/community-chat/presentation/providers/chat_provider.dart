import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:easy_bake_mobile/core/localization/app_locale_controller.dart';
import 'package:easy_bake_mobile/core/network/api_client.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../data/services/services.dart';
import '../../domain/models/models.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../recipes/data/services/recipe_service.dart';
import '../../../recipes/domain/models/recipe_model.dart';

final sharedRecipeByIdProvider = FutureProvider.family<RecipeModel, String>((
  ref,
  recipeId,
) async {
  final service = ref.read(recipeServiceProvider);
  try {
    return await service.fetchRecipeById(recipeId);
  } catch (error) {
    rethrow;
  }
});

// Messages notifier
final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
      ChatMessagesNotifier.new,
    );

class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void addPendingMessage(ChatMessage message) {
    state = [...state, message];
  }

  void markMessageAsSent(ChatMessage serverMessage) {
    final messages = [...state];

    final pendingIndex = messages.indexWhere(
      (message) =>
          message.isPending &&
          message.type == serverMessage.type &&
          (message.type != ChatMessageType.recipe ||
              message.recipeId == serverMessage.recipeId) &&
          (message.userId == serverMessage.userId ||
              (message.userEmail.isNotEmpty &&
                  serverMessage.userEmail.isNotEmpty &&
                  message.userEmail == serverMessage.userEmail)) &&
          message.content == serverMessage.content,
    );

    if (pendingIndex == -1) {
      final existingIndex = messages.indexWhere(
        (message) => message.id == serverMessage.id,
      );
      if (existingIndex == -1) {
        state = [...messages, serverMessage];
      } else {
        messages[existingIndex] = serverMessage;
        state = messages;
      }
      return;
    }

    final pendingMessage = messages[pendingIndex];
    messages[pendingIndex] = serverMessage.copyWith(
      localId: pendingMessage.localId,
      deliveryStatus: ChatMessageDeliveryStatus.sent,
    );
    state = messages;
  }

  void removePendingMessage(String localId) {
    state = state.where((message) => message.localId != localId).toList();
  }

  void setMessages(
    List<ChatMessage> messages, {
    bool preservePendingMessages = false,
  }) {
    if (!preservePendingMessages) {
      state = messages;
      return;
    }

    final pendingMessages = state
        .where((message) => message.isPending)
        .toList();
    final mergedMessages = [...messages, ...pendingMessages]
      ..sort((left, right) {
        final createdAtComparison = left.createdAt.compareTo(right.createdAt);
        if (createdAtComparison != 0) {
          return createdAtComparison;
        }
        return left.id.compareTo(right.id);
      });

    state = mergedMessages;
  }

  void clear() {
    state = [];
  }
}

// Service notifier
final chatServiceProvider =
    NotifierProvider<ChatServiceNotifier, ChatSocketService?>(
      ChatServiceNotifier.new,
    );

enum ChatConnectionState { disconnected, connecting, connected }

// Error state
final chatErrorProvider = NotifierProvider<ChatErrorNotifier, String?>(
  () => ChatErrorNotifier(),
);

class ChatErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? error) {
    if (state == error) {
      return;
    }
    state = error;
  }
}

AppLocalizations _chatLocalizations() {
  final locale =
      appLocaleNotifier.value ??
      WidgetsBinding.instance.platformDispatcher.locale;
  return lookupAppLocalizations(locale);
}

String _chatUnavailableMessage() =>
    _chatLocalizations().communityChatUnavailableMessage;

String _chatRefreshFailedMessage() =>
    _chatLocalizations().communityChatRefreshFailedMessage;

String _chatIdentityMessage() =>
    _chatLocalizations().communityChatIdentityMessage;

String _chatSendFailedMessage() =>
    _chatLocalizations().communityChatSendFailedMessage;

// Connection status
final chatConnectionStateProvider =
    NotifierProvider<ChatConnectionNotifier, ChatConnectionState>(
      ChatConnectionNotifier.new,
    );

class ChatConnectionNotifier extends Notifier<ChatConnectionState> {
  @override
  ChatConnectionState build() => ChatConnectionState.disconnected;

  void setState(ChatConnectionState connectionState) {
    state = connectionState;
  }
}

class ChatServiceNotifier extends Notifier<ChatSocketService?> {
  @override
  ChatSocketService? build() {
    ref.listen(authNotifierProvider, (previous, next) {
      final previousToken = previous?.accessToken ?? '';
      final nextToken = next.accessToken ?? '';

      if (previousToken == nextToken) {
        return;
      }

      final currentService = state;
      if (currentService != null) {
        unawaited(currentService.disconnect());
      }

      state = null;
      ref.read(chatMessagesProvider.notifier).clear();
      ref.read(chatErrorProvider.notifier).setError(null);
      ref
          .read(chatConnectionStateProvider.notifier)
          .setState(ChatConnectionState.disconnected);
    });

    return null;
  }

  Future<void> _loadMessageHistory({
    bool preservePendingMessages = true,
  }) async {
    final authState = ref.read(authNotifierProvider);
    final token = authState.accessToken;

    if (token == null || token.isEmpty) {
      throw StateError('Missing chat auth token');
    }

    final chatServerUrl = ref.read(chatServiceBaseUrlProvider);
    final dio = Dio(
      BaseOptions(
        baseUrl: chatServerUrl,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final response = await dio.get<List<dynamic>>(
      '/messages',
      queryParameters: {'limit': 50},
    );

    final rawMessages = response.data ?? const [];
    final messages = rawMessages
        .map((message) => ChatMessage.fromJson(message as Map<String, dynamic>))
        .toList();

    ref
        .read(chatMessagesProvider.notifier)
        .setMessages(
          messages,
          preservePendingMessages: preservePendingMessages,
        );

    final recipeIds = ref
        .read(chatMessagesProvider)
        .where(
          (message) =>
              message.type == ChatMessageType.recipe &&
              (message.recipeId?.trim().isNotEmpty ?? false),
        )
        .map((message) => message.recipeId!.trim())
        .toSet();

    for (final recipeId in recipeIds) {
      ref.invalidate(sharedRecipeByIdProvider(recipeId));
    }
  }

  Future<void> initializeChat() async {
    ChatSocketService? chatService;
    try {
      ref
          .read(chatConnectionStateProvider.notifier)
          .setState(ChatConnectionState.connecting);

      if (state != null) {
        await state!.disconnect();
        state = null;
      }

      await _loadMessageHistory();

      final authState = ref.read(authNotifierProvider);
      final token = authState.accessToken;
      if (token == null || token.isEmpty) {
        ref
            .read(chatConnectionStateProvider.notifier)
            .setState(ChatConnectionState.disconnected);
        return;
      }

      final chatServerUrl = ref.read(chatServiceBaseUrlProvider);

      chatService = ChatSocketService(serverUrl: chatServerUrl, token: token);

      // Setup callbacks
      chatService.onMessageHistory = (messages) {
        ref
            .read(chatMessagesProvider.notifier)
            .setMessages(messages, preservePendingMessages: true);
      };

      chatService.onMessage = (message) {
        ref.read(chatMessagesProvider.notifier).markMessageAsSent(message);
      };

      chatService.onUserUpdated = (userId, displayName) {
        try {
          // If the updated user is the current user, update auth state displayName
          final authState = ref.read(authNotifierProvider);
          if (authState.userId != null && authState.userId == userId) {
            ref
                .read(authNotifierProvider.notifier)
                .setAuth(
                  accessToken: authState.accessToken ?? '',
                  userId: authState.userId,
                  email: authState.email,
                  fullName: authState.fullName,
                  displayName: displayName,
                );
          }

          // Update in-memory messages to reflect new display name where applicable
          final messages = ref.read(chatMessagesProvider);
          final updated = messages.map((m) {
            if (m.userId == userId) {
              return m.copyWith(userFullName: displayName ?? m.userFullName);
            }
            return m;
          }).toList();
          ref
              .read(chatMessagesProvider.notifier)
              .setMessages(updated, preservePendingMessages: true);
        } catch (e) {
          debugPrint('[Chat] Error handling user_updated: $e');
        }
      };

      chatService.onError = (error) {
        ref
            .read(chatErrorProvider.notifier)
            .setError(_chatUnavailableMessage());
      };

      chatService.onConnectionStateChanged = (isConnected) {
        ref
            .read(chatConnectionStateProvider.notifier)
            .setState(
              isConnected
                  ? ChatConnectionState.connected
                  : ChatConnectionState.disconnected,
            );
      };

      // Connect
      await chatService.connect();

      ref
          .read(chatConnectionStateProvider.notifier)
          .setState(ChatConnectionState.connected);
      ref.read(chatErrorProvider.notifier).setError(null);

      state = chatService;
    } catch (e) {
      if (chatService != null) {
        await chatService.disconnect();
      }
      ref
          .read(chatConnectionStateProvider.notifier)
          .setState(ChatConnectionState.disconnected);
      ref.read(chatErrorProvider.notifier).setError(_chatUnavailableMessage());
      state = null;
    }
  }

  Future<void> refreshMessages() async {
    final service = state;
    final connectionState = ref.read(chatConnectionStateProvider);
    final shouldReconnect =
        service == null ||
        !service.isConnected ||
        connectionState != ChatConnectionState.connected;

    if (shouldReconnect) {
      await initializeChat();
      return;
    }

    try {
      await _loadMessageHistory();
      ref.read(chatErrorProvider.notifier).setError(null);
    } catch (e) {
      ref
          .read(chatErrorProvider.notifier)
          .setError(_chatRefreshFailedMessage());
    }
  }

  void sendMessage(String content) {
    final chatService = state;
    if (chatService == null) {
      ref.read(chatErrorProvider.notifier).setError(_chatUnavailableMessage());
      return;
    }

    final authState = ref.read(authNotifierProvider);
    final userId = authState.userId?.trim() ?? '';
    final userEmail = authState.email?.trim() ?? '';
    if (userId.isEmpty && userEmail.isEmpty) {
      ref.read(chatErrorProvider.notifier).setError(_chatIdentityMessage());
      return;
    }

    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      return;
    }

    // Use display name from auth state (source of truth from server)
    final displayName = authState.displayName;

    final localId = DateTime.now().microsecondsSinceEpoch.toString();
    final pendingMessage = ChatMessage.pending(
      localId: localId,
      userId: userId,
      userEmail: userEmail,
      userFullName: displayName,
      content: trimmedContent,
      createdAt: DateTime.now(),
    );

    ref.read(chatMessagesProvider.notifier).addPendingMessage(pendingMessage);

    final sent = chatService.sendMessage(content: trimmedContent);
    if (!sent) {
      ref.read(chatErrorProvider.notifier).setError(_chatSendFailedMessage());
      ref.read(chatMessagesProvider.notifier).removePendingMessage(localId);
    }
  }

  void sendRecipeMessage(String recipeId) {
    final chatService = state;
    if (chatService == null) {
      ref.read(chatErrorProvider.notifier).setError(_chatUnavailableMessage());
      return;
    }

    final authState = ref.read(authNotifierProvider);
    final userId = authState.userId?.trim() ?? '';
    final userEmail = authState.email?.trim() ?? '';
    if (userId.isEmpty && userEmail.isEmpty) {
      ref.read(chatErrorProvider.notifier).setError(_chatIdentityMessage());
      return;
    }

    final normalizedRecipeId = recipeId.trim();
    if (normalizedRecipeId.isEmpty) {
      return;
    }

    final localId = DateTime.now().microsecondsSinceEpoch.toString();
    const pendingContent = 'Shared a recipe';
    final pendingMessage = ChatMessage.pending(
      localId: localId,
      userId: userId,
      userEmail: userEmail,
      userFullName: authState.displayName,
      content: pendingContent,
      type: ChatMessageType.recipe,
      recipeId: normalizedRecipeId,
      createdAt: DateTime.now(),
    );

    ref.read(chatMessagesProvider.notifier).addPendingMessage(pendingMessage);

    final sent = chatService.sendMessage(
      content: pendingContent,
      type: ChatMessageType.recipe,
      recipeId: normalizedRecipeId,
    );

    if (!sent) {
      ref.read(chatErrorProvider.notifier).setError(_chatSendFailedMessage());
      ref.read(chatMessagesProvider.notifier).removePendingMessage(localId);
    }
  }

  Future<void> dispose() async {
    if (state != null) {
      await state!.disconnect();
    }
    ref
        .read(chatConnectionStateProvider.notifier)
        .setState(ChatConnectionState.disconnected);
    state = null;
  }
}
