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
          (message.type == serverMessage.type ||
              (message.userId == 'ai-chef' &&
                  (serverMessage.type == ChatMessageType.aiAssistant ||
                      serverMessage.type == ChatMessageType.recipePreview))) &&
          (message.type != ChatMessageType.recipe ||
              message.recipeId == serverMessage.recipeId) &&
          (message.userId == serverMessage.userId ||
              (message.userEmail.isNotEmpty &&
                  serverMessage.userEmail.isNotEmpty &&
                  message.userEmail == serverMessage.userEmail)) &&
          (message.type == ChatMessageType.aiAssistant ||
              message.type == ChatMessageType.recipePreview ||
              message.content == serverMessage.content ||
              _stripAiChefMention(message.content) == serverMessage.content),
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
    final resolvedContent = pendingMessage.type == ChatMessageType.aiAssistant
        ? serverMessage.content
        : pendingMessage.content;
    messages[pendingIndex] = serverMessage.copyWith(
      localId: pendingMessage.localId,
      deliveryStatus: ChatMessageDeliveryStatus.sent,
      content: resolvedContent,
    );
    state = messages;
        // Notify chat service notifier in case an AI failure message was deferred
        // until the user's message was marked as sent.
        try {
          final questionLocalId = pendingMessage.localId;
          if (questionLocalId != null && questionLocalId.isNotEmpty) {
            final notifier = ref.read(chatServiceProvider.notifier);
            // Start AI typing indicator after user's message is confirmed sent
            notifier._maybeStartAiTypingForLocalId(questionLocalId);
            // Deliver any deferred AI failure that was waiting for message delivery
            notifier._maybeDeliverDeferredAiFailureForLocalId(questionLocalId);
          }
        } catch (_) {}
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

    final currentMessages = [...state];
    final pendingMessages = currentMessages
        .where((message) => message.isPending)
        .toList();

    final mergedMessages = messages.map((incomingMessage) {
      final existingIndex = currentMessages.indexWhere(
        (message) => message.id == incomingMessage.id,
      );
      if (existingIndex != -1) {
        final existingMessage = currentMessages[existingIndex];
        if (_shouldPreserveAiChefDisplayContent(
          existingMessage,
          incomingMessage,
        )) {
          return incomingMessage.copyWith(content: existingMessage.content);
        }
      }

      return incomingMessage;
    }).toList();

    final combinedMessages = [...mergedMessages, ...pendingMessages]
      ..sort((left, right) {
        final createdAtComparison = left.createdAt.compareTo(right.createdAt);
        if (createdAtComparison != 0) {
          return createdAtComparison;
        }
        return left.id.compareTo(right.id);
      });

    state = combinedMessages;
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

String _communityChatAiFailureMessage() =>
    _chatLocalizations().aiChefGenericErrorMessage;

String _stripAiChefMention(String content) {
  final cleaned = content.replaceAll(
    RegExp(r'@aichef\b', caseSensitive: false),
    '',
  );
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _shouldPreserveAiChefDisplayContent(
  ChatMessage existing,
  ChatMessage incoming,
) {
  final existingContent = existing.content.trim();
  final incomingContent = incoming.content.trim();

  return existingContent.isNotEmpty &&
      existingContent != incomingContent &&
      existingContent.toLowerCase().contains('@aichef') &&
      _stripAiChefMention(existingContent) == incomingContent;
}

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
  bool _awaitingAiChefResponse = false;
  String? _awaitingAiChefTypingLocalId;
  String? _awaitingAiChefQuestionLocalId;
  String? _awaitingAiChefQuestionContent;
  bool _aiRequestSent = false;
  bool _deferAiChefFailure = false;
  bool _suppressNextSocketError = false;

  static const String _aiChefUnavailableServerMessage =
      'AI assistant is temporarily unavailable. Please try again.';

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
        if (message.type == ChatMessageType.aiAssistant ||
            message.type == ChatMessageType.recipePreview) {
          _awaitingAiChefResponse = false;
          _awaitingAiChefTypingLocalId = null;
          _awaitingAiChefQuestionLocalId = null;
          _awaitingAiChefQuestionContent = null;
          _aiRequestSent = false;
          _deferAiChefFailure = false;
        }
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
        debugPrint('[Chat] socket error callback: $error');
        if (_suppressNextSocketError) {
          _suppressNextSocketError = false;
          return;
        }

        final normalizedError = error.trim().toLowerCase();
        debugPrint('[Chat] normalized socket error: $normalizedError');
        final isAiChefFailure =
            _awaitingAiChefResponse ||
            normalizedError == _aiChefUnavailableServerMessage.toLowerCase() ||
          normalizedError.contains('ai assistant is temporarily unavailable') ||
          normalizedError.contains('ai assistant request failed') ||
          normalizedError.contains('403');

        if (isAiChefFailure) {
          debugPrint('[Chat] detected AI chef failure: awaiting=$_awaitingAiChefResponse');
          _showAiChefFailureMessage();
          return;
        }

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

    final cleanedContent = _stripAiChefMention(trimmedContent);
    if (cleanedContent.isEmpty) {
      return;
    }

    final isAiChefQuestion = cleanedContent != trimmedContent;

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
    // Track the user's local id when asking the AI Chef so we can defer
    // showing the AI failure message until the user's message is marked as sent.

    final sent = chatService.sendMessage(content: trimmedContent);
    if (!sent) {
      ref.read(chatErrorProvider.notifier).setError(_chatSendFailedMessage());
      ref.read(chatMessagesProvider.notifier).removePendingMessage(localId);
      return;
    }

    if (isAiChefQuestion) {
      _awaitingAiChefQuestionLocalId = localId;
      _awaitingAiChefQuestionContent = cleanedContent;
      _aiRequestSent = false;
      _awaitingAiChefResponse = true;
      _awaitingAiChefTypingLocalId = '$localId-ai-typing';
      _suppressNextSocketError = false;
      // The actual AI request will be sent once the user's message is
      // confirmed sent (in _maybeStartAiTypingForLocalId) to avoid
      // races or transient socket disconnects.
    }
  }

  void _showAiChefFailureMessage() {
    final typingLocalId = _awaitingAiChefTypingLocalId;
    if (typingLocalId != null) {
      ref
          .read(chatMessagesProvider.notifier)
          .removePendingMessage(typingLocalId);
    }

    // If the user's message that triggered the AI request is still pending,
    // defer adding the AI failure message until that message is marked as sent
    // so the UI shows the "delivered" state (V) instead of a loading animation.
    final questionLocalId = _awaitingAiChefQuestionLocalId;
    final messages = ref.read(chatMessagesProvider);
    final userMessageStillPending = questionLocalId != null &&
        messages.any((m) => m.localId == questionLocalId && m.isPending);

    if (userMessageStillPending) {
      _deferAiChefFailure = true;

      // Clear awaiting typing indicator and mark not awaiting response,
      // but keep the question local id so we can deliver the failure later.
      _awaitingAiChefResponse = false;
      _awaitingAiChefTypingLocalId = null;
      _awaitingAiChefQuestionContent = null;
      _aiRequestSent = false;
      _suppressNextSocketError = true;
      ref.read(chatErrorProvider.notifier).setError(null);
      return;
    }

    ref
        .read(chatMessagesProvider.notifier)
        .addMessage(
          ChatMessage(
            id: 'ai-chef-local-${DateTime.now().microsecondsSinceEpoch}',
            userId: 'ai-chef',
            userEmail: 'ai-chef@easybake.local',
            userFullName: 'AI Chef',
            content: _communityChatAiFailureMessage(),
            type: ChatMessageType.aiAssistant,
            createdAt: DateTime.now(),
          ),
        );

    _awaitingAiChefResponse = false;
    _awaitingAiChefTypingLocalId = null;
    _suppressNextSocketError = true;
    ref.read(chatErrorProvider.notifier).setError(null);
  }

  // Called when a user's pending message is marked as sent. If we previously
  // deferred the AI failure message for that question, deliver it now.
  void _maybeDeliverDeferredAiFailureForLocalId(String localId) {
    if (!_deferAiChefFailure) return;
    if (_awaitingAiChefQuestionLocalId == null) return;
    if (_awaitingAiChefQuestionLocalId != localId) return;
    // Try to send the AI failure message via the socket so it is visible
    // to everyone in the chat and marked as an AI assistant message. If
    // sending fails, fall back to adding a local message.
    ref
        .read(chatMessagesProvider.notifier)
        .addMessage(
          ChatMessage(
            id: 'ai-chef-local-${DateTime.now().microsecondsSinceEpoch}',
            userId: 'ai-chef',
            userEmail: 'ai-chef@easybake.local',
            userFullName: 'AI Chef',
            content: _communityChatAiFailureMessage(),
            type: ChatMessageType.aiAssistant,
            createdAt: DateTime.now(),
          ),
        );

    _deferAiChefFailure = false;
    _awaitingAiChefQuestionLocalId = null;
    _awaitingAiChefQuestionContent = null;
    _aiRequestSent = false;
    _awaitingAiChefResponse = false;
    _awaitingAiChefTypingLocalId = null;
    _suppressNextSocketError = true;
    ref.read(chatErrorProvider.notifier).setError(null);
  }

  // Called when a user's pending message is marked as sent. If we were
  // awaiting an AI Chef response for that question, start the AI typing
  // indicator (a pending aiAssistant message) so the UI shows typing after
  // the user's message is delivered.
  void _maybeStartAiTypingForLocalId(String localId) {
    if (_awaitingAiChefQuestionLocalId == null) return;
    if (_awaitingAiChefQuestionLocalId != localId) return;
    final typingLocalId = _awaitingAiChefTypingLocalId;
    if (typingLocalId == null || typingLocalId.isEmpty) return;

    final messages = ref.read(chatMessagesProvider);
    final alreadyPresent = messages.any((m) => m.localId == typingLocalId);
    if (alreadyPresent) return;

    ref
        .read(chatMessagesProvider.notifier)
        .addPendingMessage(
          ChatMessage.pending(
            localId: typingLocalId,
            userId: 'ai-chef',
            userEmail: '',
            userFullName: 'AI Chef',
            content: '',
            type: ChatMessageType.aiAssistant,
            createdAt: DateTime.now(),
          ),
        );

    // After showing typing, send the AI request to the server if not already sent.
    if (!_aiRequestSent && _awaitingAiChefQuestionContent != null) {
      final service = state;
      final contentToSend = _awaitingAiChefQuestionContent!;
      debugPrint('[Chat] sending AI request to server: content="$contentToSend"');
      final sent = service != null && service.isConnected
          ? service.sendMessage(
              content: contentToSend,
              type: ChatMessageType.aiAssistant,
              assistantFallback: _communityChatAiFailureMessage(),
            )
          : false;
      debugPrint('[Chat] AI request sent result: $sent');
      _aiRequestSent = sent;
      if (!sent) {
        // If sending failed, show failure immediately (it will be deferred
        // earlier only when user's message was pending).
        debugPrint('[Chat] AI request failed to send, showing failure');
        _showAiChefFailureMessage();
      }
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
