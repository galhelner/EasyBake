import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../recipes/domain/models/recipe_model.dart';
import '../../../recipes/presentation/pages/recipe_details_page.dart';
import '../../../recipes/presentation/widgets/recipe_list/delete_confirmation_dialog.dart';
import '../../../recipes/presentation/widgets/recipe_list/deleting_status_card.dart';
import '../../data/services/chat_service.dart';
import '../widgets/ai_chef_chat_popup_composer.dart';
import '../widgets/ai_chef_chat_popup_header.dart';
import '../widgets/chat_message_builder.dart';
import '../../../home/presentation/pages/home_tabs_page.dart';
import '../../../shopping-list/presentation/providers/shopping_list_providers.dart';

Future<void> showAiChefChatPopup(
  BuildContext context, {
  required String pageContext,
  required ChatService chatService,
  required ValueChanged<Map<String, dynamic>> onOpenRecipeCreated,
  String? recipeId,
}) {
  return showAiChefChatPopupDialog(
    context,
    pageContext: pageContext,
    chatService: chatService,
    onOpenRecipeCreated: onOpenRecipeCreated,
    recipeId: recipeId,
  );
}

void notifyRecipeSaved(String recipeName) {
  notifyRecipeSavedInDialog(recipeName);
}

final _chatDialogStateKey = GlobalKey<_AiChefChatPopupDialogState>();

Future<void> showAiChefChatPopupDialog(
  BuildContext context, {
  required String pageContext,
  required ChatService chatService,
  required ValueChanged<Map<String, dynamic>> onOpenRecipeCreated,
  String? recipeId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => _AiChefChatPopupDialog(
      key: _chatDialogStateKey,
      pageContext: pageContext,
      recipeId: recipeId,
      chatService: chatService,
      onOpenRecipeCreated: onOpenRecipeCreated,
    ),
  );
}

void notifyRecipeSavedInDialog(String recipeName) {
  _chatDialogStateKey.currentState?.addRecipeSavedConfirmation(recipeName);
}

class _AiChefChatPopupDialog extends ConsumerStatefulWidget {
  const _AiChefChatPopupDialog({
    super.key,
    required this.pageContext,
    required this.chatService,
    required this.onOpenRecipeCreated,
    this.recipeId,
  });

  final String pageContext;
  final String? recipeId;
  final ChatService chatService;
  final ValueChanged<Map<String, dynamic>> onOpenRecipeCreated;

  @override
  ConsumerState<_AiChefChatPopupDialog> createState() =>
      _AiChefChatPopupDialogState();
}

class _AiChefChatPopupDialogState
    extends ConsumerState<_AiChefChatPopupDialog> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [const ChatMessage.connectionChecking()];

  StreamSubscription<ChatEvent>? _chatSubscription;
  late final String _sessionId;
  bool _isAwaitingResponse = false;
  bool _isServiceOnline = false;
  bool _isRefreshingConnection = false;
  bool _isCheckingInitialConnection = true;
  int? _typingMessageIndex;
  int? _currentAiResponseMessageIndex;
  bool _recipeIntentAnnounced = false;
  bool _showToast = false;
  Timer? _toastTimer;

  String get _normalizedPageContext {
    final normalized = widget.pageContext.trim().toLowerCase();
    if (normalized == 'recipe_details') {
      return 'recipe_detail';
    }
    if (normalized == 'home' || normalized == 'recipe_detail') {
      return normalized;
    }
    return 'home';
  }

  @override
  void initState() {
    super.initState();
    final random = Random();
    final time = DateTime.now().millisecondsSinceEpoch;
    _sessionId = 'session_${time}_${random.nextInt(1000000)}';
    _initializeConnectionState();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _toastTimer?.cancel();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectionState() async {
    final isOnline = await widget.chatService.pingService();
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final authState = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authNotifierProvider);
    final fullName = authState.fullName?.trim();
    final greeting = fullName != null && fullName.isNotEmpty
        ? l10n.aiChefGreetingWithName(fullName)
        : l10n.aiChefGreetingWithoutName;

    final historyMessages = <ChatMessage>[];
    if (isOnline) {
      try {
        final history = await widget.chatService.getChatHistory(
          pageContext: _normalizedPageContext,
          recipeId: widget.recipeId,
        );
        for (final item in history) {
          final content = item['content']?.toString() ?? '';
          final isAi = item['isAi'] as bool? ?? false;
          final messageType = item['messageType']?.toString() ?? 'text';
          final metadata = item['metadata'];

          if (messageType == 'recipePreview' && metadata is Map) {
            historyMessages.add(
              ChatMessage.recipePreview(
                recipeTitle: content,
                recipePayload: Map<String, dynamic>.from(metadata),
                imageUrl: 'assets/default_recipe.jpg',
              ),
            );
          } else if (messageType == 'searchResults' && metadata is Map) {
            historyMessages.add(
              ChatMessage.searchResults(
                recipes: metadata['recipes'] as List<dynamic>? ?? [],
              ),
            );
          } else if (messageType == 'shoppingListAdded' && metadata is Map) {
            historyMessages.add(
              ChatMessage.shoppingListAdded(
                items: List<String>.from(metadata['items'] ?? const []),
              ),
            );
          } else if (messageType == 'swapSummary' && metadata is Map) {
            historyMessages.add(
              ChatMessage.swapSummary(
                title: content,
                swaps: List<String>.from(metadata['swaps'] ?? const []),
              ),
            );
          } else if (content.isNotEmpty) {
            historyMessages.add(
              ChatMessage.text(
                content,
                sender: isAi ? ChatSender.ai : ChatSender.user,
              ),
            );
          }
        }
      } catch (_) {
        // Ignore and fallback to greeting
      }
    }

    setState(() {
      _isServiceOnline = isOnline;
      _isCheckingInitialConnection = false;
      _messages.clear();
      if (isOnline) {
        if (historyMessages.isNotEmpty) {
          _messages.addAll(historyMessages);
        } else {
          _messages.add(ChatMessage.text(greeting));
        }
      } else {
        _messages.add(ChatMessage.text(l10n.aiChefServiceUnavailableMessage));
      }
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    if (_isAwaitingResponse || _isCheckingInitialConnection) {
      return;
    }

    final message = _questionController.text.trim();
    if (message.isEmpty) {
      return;
    }

    _chatSubscription?.cancel();

    setState(() {
      _messages.add(ChatMessage.text(message, sender: ChatSender.user));
      _messages.add(const ChatMessage.typing());
      _typingMessageIndex = _messages.length - 1;
      _currentAiResponseMessageIndex = null;
      _isAwaitingResponse = true;
    });

    _questionController.clear();
    _scrollToBottom();

    final contextForRequest =
        _normalizedPageContext == 'recipe_detail' &&
            (widget.recipeId == null || widget.recipeId!.trim().isEmpty)
        ? 'home'
        : _normalizedPageContext;

    _recipeIntentAnnounced = false;
    _startChatRequest(message, contextForRequest);
  }

  void _startChatRequest(String message, String contextForRequest) {
    _chatSubscription = widget.chatService
        .sendPrompt(
          prompt: message,
          pageContext: contextForRequest,
          sessionId: _sessionId,
          recipeId: widget.recipeId,
        )
        .listen(_handleChatEvent);
  }

  void _handleChatEvent(ChatEvent event) {
    final l10n = AppLocalizations.of(context)!;

    if (!mounted) {
      return;
    }

    switch (event.type) {
      case ChatEventType.textDelta:
        final delta = event.delta;
        if (delta == null || delta.isEmpty) {
          return;
        }

        setState(() {
          _isServiceOnline = true;
          _removeTypingIndicator();
          if (_currentAiResponseMessageIndex == null) {
            _messages.add(const ChatMessage.text(''));
            _currentAiResponseMessageIndex = _messages.length - 1;
          }

          final index = _currentAiResponseMessageIndex!;
          final existing = _messages[index];
          _messages[index] = existing.copyWith(text: '${existing.text}$delta');
        });
        _scrollToBottom();
      case ChatEventType.intentDetected:
        final intent = event.intent;
        if (intent == null) {
          return;
        }

        if (intent == 'CREATE_RECIPE' && !_recipeIntentAnnounced) {
          setState(() {
            _isServiceOnline = true;
            _removeTypingIndicator();
            if (_currentAiResponseMessageIndex == null) {
              _messages.add(ChatMessage.text(l10n.aiChefCreatingRecipeMessage));
              _currentAiResponseMessageIndex = _messages.length - 1;
            } else {
              final index = _currentAiResponseMessageIndex!;
              final existing = _messages[index];
              final separator = existing.text.isNotEmpty && !existing.text.endsWith('\n') ? '\n' : '';
              _messages[index] = existing.copyWith(
                text: '${existing.text}$separator${l10n.aiChefCreatingRecipeMessage}',
              );
            }
            _messages.add(const ChatMessage.typing());
            _typingMessageIndex = _messages.length - 1;
            _recipeIntentAnnounced = true;
          });
          _scrollToBottom();
        } else if (intent == 'ADD_TO_SHOPPING_LIST' &&
            !_recipeIntentAnnounced) {
          setState(() {
            _isServiceOnline = true;
            _removeTypingIndicator();
            if (_currentAiResponseMessageIndex == null) {
              _messages.add(
                ChatMessage.text(l10n.aiChefAddingToShoppingListMessage),
              );
              _currentAiResponseMessageIndex = _messages.length - 1;
            } else {
              final index = _currentAiResponseMessageIndex!;
              final existing = _messages[index];
              final separator = existing.text.isNotEmpty && !existing.text.endsWith('\n') ? '\n' : '';
              _messages[index] = existing.copyWith(
                text: '${existing.text}$separator${l10n.aiChefAddingToShoppingListMessage}',
              );
            }
            _messages.add(const ChatMessage.typing());
            _typingMessageIndex = _messages.length - 1;
            _recipeIntentAnnounced = true;
          });
          _scrollToBottom();
        }
      case ChatEventType.recipeCreated:
        final recipe = event.recipe;
        final recipeTitle =
            recipe?['title']?.toString() ?? l10n.aiChefYourRecipeFallback;
        const imageUrl = 'assets/default_recipe.jpg';

        setState(() {
          _isServiceOnline = true;
          _removeTypingIndicator();
          if (_currentAiResponseMessageIndex != null &&
              _currentAiResponseMessageIndex! < _messages.length) {
            final index = _currentAiResponseMessageIndex!;
            final existing = _messages[index];
            _messages[index] = existing.copyWith(
              recipeTitle: recipeTitle,
              imageUrl: imageUrl,
              recipePayload: recipe,
            );
          } else {
            _messages.add(
              ChatMessage.text('').copyWith(
                recipeTitle: recipeTitle,
                imageUrl: imageUrl,
                recipePayload: recipe,
              ),
            );
            _currentAiResponseMessageIndex = _messages.length - 1;
          }
          _recipeIntentAnnounced = false;
        });
        _scrollToBottom();
      case ChatEventType.shoppingListAdded:
        final items = event.shoppingListItems;
        setState(() {
          _isServiceOnline = true;
          _removeTypingIndicator();
          if (_currentAiResponseMessageIndex != null &&
              _currentAiResponseMessageIndex! < _messages.length) {
            final index = _currentAiResponseMessageIndex!;
            final existing = _messages[index];
            _messages[index] = existing.copyWith(
              shoppingListItems: items != null ? List<String>.from(items) : const [],
            );
          } else {
            _messages.add(
              ChatMessage.text('').copyWith(
                shoppingListItems: items != null ? List<String>.from(items) : const [],
              ),
            );
            _currentAiResponseMessageIndex = _messages.length - 1;
          }
          _recipeIntentAnnounced = false;
        });
        _scrollToBottom();
      case ChatEventType.searchResults:
        final recipes = event.searchResults;
        if (recipes == null || recipes.isEmpty) {
          return;
        }

        setState(() {
          _isServiceOnline = true;
          _removeTypingIndicator();
          if (_currentAiResponseMessageIndex != null &&
              _currentAiResponseMessageIndex! < _messages.length) {
            final index = _currentAiResponseMessageIndex!;
            final existing = _messages[index];
            _messages[index] = existing.copyWith(
              recipes: recipes,
            );
          } else {
            _messages.add(
              ChatMessage.text('').copyWith(
                recipes: recipes,
              ),
            );
            _currentAiResponseMessageIndex = _messages.length - 1;
          }
        });
        _scrollToBottom();
      case ChatEventType.error:
        final errorMessage = _localizeChatErrorMessage(
          event.errorKind,
          l10n,
          event.isConnectionIssue,
        );

        setState(() {
          _isServiceOnline = !event.isConnectionIssue;
          _removeTypingIndicator();
          _currentAiResponseMessageIndex = null;
          _messages.add(ChatMessage.text(errorMessage));
          _recipeIntentAnnounced = false;
          _isAwaitingResponse = false;
        });
        _scrollToBottom();
      case ChatEventType.metadata:
        final metadata = event.metadata;
        final swapSuggestions = _extractSwapSuggestions(metadata);
        if (swapSuggestions.isEmpty) {
          return;
        }

        setState(() {
          _isServiceOnline = true;
          if (_currentAiResponseMessageIndex != null &&
              _currentAiResponseMessageIndex! < _messages.length) {
            final index = _currentAiResponseMessageIndex!;
            final existing = _messages[index];
            _messages[index] = existing.copyWith(
              title: l10n.aiChefSuggestedSubstitutionsTitle,
              swaps: swapSuggestions,
            );
          } else {
            _messages.add(
              ChatMessage.text('').copyWith(
                title: l10n.aiChefSuggestedSubstitutionsTitle,
                swaps: swapSuggestions,
              ),
            );
            _currentAiResponseMessageIndex = _messages.length - 1;
          }
        });
        _scrollToBottom();
        return;
      case ChatEventType.done:
        setState(() {
          _removeTypingIndicator();
          if (_currentAiResponseMessageIndex != null &&
              _currentAiResponseMessageIndex! < _messages.length) {
            final index = _currentAiResponseMessageIndex!;
            final existing = _messages[index];

            ChatMessageKind finalKind = ChatMessageKind.text;
            if (existing.recipePayload != null) {
              finalKind = ChatMessageKind.recipePreview;
            } else if (existing.shoppingListItems != null &&
                existing.shoppingListItems!.isNotEmpty) {
              finalKind = ChatMessageKind.shoppingListAdded;
            } else if (existing.recipes != null &&
                existing.recipes!.isNotEmpty) {
              finalKind = ChatMessageKind.searchResults;
            } else if (existing.swaps != null &&
                existing.swaps!.isNotEmpty) {
              finalKind = ChatMessageKind.swapSummary;
            }

            _messages[index] = existing.copyWith(kind: finalKind);
          }
          _normalizeCurrentAiResponseMessage();
          _currentAiResponseMessageIndex = null;
          _recipeIntentAnnounced = false;
          _isAwaitingResponse = false;
        });
        _scrollToBottom();
    }
  }

  String _localizeChatErrorMessage(
    ChatErrorKind? errorKind,
    AppLocalizations l10n,
    bool isConnectionIssue,
  ) {
    switch (errorKind) {
      case ChatErrorKind.emptyPrompt:
        return l10n.aiChefErrorPleaseTypeMessageFirst;
      case ChatErrorKind.sendFailed:
        return l10n.aiChefErrorCouldNotSendMessage;
      case ChatErrorKind.emptyResponse:
        return l10n.aiChefErrorEmptyResponse;
      case ChatErrorKind.streamInterrupted:
        return l10n.aiChefErrorStreamInterrupted;
      case ChatErrorKind.assistantCouldNotComplete:
        return l10n.aiChefErrorAssistantCouldNotComplete;
      case ChatErrorKind.couldNotReadServerResponse:
        return l10n.aiChefErrorCouldNotReadServerResponse;
      case ChatErrorKind.responseUnsupportedFormat:
        return l10n.aiChefErrorResponseUnsupportedFormat;
      case ChatErrorKind.unexpectedResponseFormat:
        return l10n.aiChefErrorUnexpectedResponseFormat;
      case ChatErrorKind.failedToParseServerResponse:
        return l10n.aiChefErrorFailedToParseServerResponse;
      case ChatErrorKind.requestFailed:
        return l10n.aiChefErrorRequestFailed;
      case ChatErrorKind.serverSlow:
        return l10n.aiChefErrorServerSlow;
      case ChatErrorKind.cannotReachServer:
        return l10n.aiChefErrorCannotReachServer;
      case ChatErrorKind.requestCancelled:
        return l10n.aiChefErrorRequestCancelled;
      case ChatErrorKind.unauthorized:
        return l10n.aiChefErrorUnauthorized;
      case ChatErrorKind.serverIssue:
        return l10n.aiChefErrorServerIssue;
      case ChatErrorKind.notFound:
        return l10n.aiChefErrorNotFound;
      case ChatErrorKind.rateLimited:
        return l10n.aiChefErrorRateLimited;
      case ChatErrorKind.validation:
        return l10n.aiChefErrorValidation;
      case ChatErrorKind.generic:
      case null:
        if (isConnectionIssue) {
          return l10n.aiChefErrorCannotReachServer;
        }
        return l10n.aiChefGenericErrorMessage;
    }
  }

  List<String> _extractSwapSuggestions(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) {
      return const [];
    }

    final candidates = [
      metadata['suggested_swaps'],
      metadata['healthier_swaps'],
      metadata['substitutions'],
      metadata['swaps'],
    ];

    final values = <String>[];
    for (final candidate in candidates) {
      if (candidate is List) {
        for (final item in candidate) {
          final text = item?.toString().trim();
          if (text != null && text.isNotEmpty) {
            values.add(text);
          }
        }
      }
    }

    return values.toSet().toList();
  }

  void _normalizeCurrentAiResponseMessage() {
    final index = _currentAiResponseMessageIndex;
    if (index == null || index < 0 || index >= _messages.length) {
      return;
    }

    final existing = _messages[index];
    if (existing.kind != ChatMessageKind.text) {
      return;
    }

    final normalized = existing.text.trimRight();
    if (normalized == existing.text) {
      return;
    }

    if (normalized.isEmpty) {
      _messages.removeAt(index);
      if (_currentAiResponseMessageIndex == index) {
        _currentAiResponseMessageIndex = null;
      }
      return;
    }

    _messages[index] = existing.copyWith(text: normalized);
  }

  void _removeTypingIndicator() {
    final typingIndex = _typingMessageIndex;
    if (typingIndex == null) {
      return;
    }

    if (typingIndex < 0 || typingIndex >= _messages.length) {
      _typingMessageIndex = null;
      return;
    }

    _messages.removeAt(typingIndex);

    if (_currentAiResponseMessageIndex != null &&
        _currentAiResponseMessageIndex! > typingIndex) {
      _currentAiResponseMessageIndex = _currentAiResponseMessageIndex! - 1;
    }

    _typingMessageIndex = null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _getCopyableText(ChatMessage message) {
    final l10n = AppLocalizations.of(context)!;
    switch (message.kind) {
      case ChatMessageKind.text:
        return message.text;
      case ChatMessageKind.recipePreview:
        return message.recipeTitle ?? '';
      case ChatMessageKind.swapSummary:
        final buffer = StringBuffer(message.title ?? l10n.aiChefSuggestedSubstitutionsTitle);
        if (message.swaps != null) {
          for (final swap in message.swaps!) {
            buffer.write('\n• $swap');
          }
        }
        return buffer.toString();
      case ChatMessageKind.searchResults:
        return message.text;
      case ChatMessageKind.shoppingListAdded:
        final buffer = StringBuffer(l10n.aiChefShoppingListAddedTitle);
        if (message.shoppingListItems != null) {
          for (final item in message.shoppingListItems!) {
            buffer.write('\n• $item');
          }
        }
        return buffer.toString();
      default:
        return message.text;
    }
  }

  void _copyMessageToClipboard(ChatMessage message) {
    final text = _getCopyableText(message);
    if (text.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    _showCopiedToastNotification();
  }

  void _showCopiedToastNotification() {
    _toastTimer?.cancel();
    setState(() {
      _showToast = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showToast = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final dialogWidth = mediaQuery.size.width < 420
        ? mediaQuery.size.width * 0.9
        : 360.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.82,
              minHeight: 460,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7F7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AiChefChatPopupHeader(
                  isCheckingInitialConnection: _isCheckingInitialConnection,
                  isServiceOnline: _isServiceOnline,
                  isRefreshingConnection: _isRefreshingConnection,
                  onRefreshConnection: _refreshConnectionStatus,
                  onClose: () => Navigator.of(context).pop(),
                  onClearChat: _hasClearableHistory ? _performClearChatHistory : null,
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isAi = message.sender == ChatSender.ai;
                      final bubbleRadius = BorderRadiusDirectional.only(
                        topStart: Radius.circular(isAi ? 3 : 12),
                        topEnd: Radius.circular(isAi ? 12 : 3),
                        bottomStart: const Radius.circular(12),
                        bottomEnd: const Radius.circular(12),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Align(
                          alignment: isAi
                              ? AlignmentDirectional.centerStart
                              : AlignmentDirectional.centerEnd,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: dialogWidth * 0.82,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: isAi
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAi
                                        ? const Color(0xFFF3F7FA)
                                        : const Color(0xFFEAF2F5),
                                    border: Border.all(
                                      color: isAi
                                          ? const Color(0xFFB8CAD8)
                                          : const Color(0xFF9FB5C6),
                                    ),
                                  ),
                                  child: isAi
                                      ? Image.asset(
                                          'assets/ai_chef_logo.png',
                                          fit: BoxFit.contain,
                                        )
                                      : const Icon(
                                          Icons.person_rounded,
                                          size: 18,
                                          color: Color(0xFF5E7388),
                                        ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: isAi ? 18 : 0,
                                    end: isAi ? 0 : 18,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFF2B3D5A),
                                      ),
                                      borderRadius: bubbleRadius,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SelectionArea(
                                          child: ChatMessageBuilder(
                                            message: message,
                                            onOpenRecipe: () {
                                              final payload = message.recipePayload;
                                              if (payload == null) {
                                                return;
                                              }
                                              final updatedPayload = Map<String, dynamic>.from(payload);
                                              updatedPayload['recipeBy'] = 'AI Chef';
                                              widget.onOpenRecipeCreated(updatedPayload);
                                            },
                                            onRecipeTap: _openRecipeDetailsFromSearch,
                                            onNavigateToShoppingList:
                                                _navigateToShoppingList,
                                          ),
                                        ),
                                        if (!isAi &&
                                            message.kind != ChatMessageKind.typing &&
                                            message.kind != ChatMessageKind.connectionChecking) ...[
                                          const SizedBox(height: 2),
                                          Align(
                                            alignment: AlignmentDirectional.centerEnd,
                                            child: InkWell(
                                              onTap: () => _copyMessageToClipboard(message),
                                              borderRadius: BorderRadius.circular(4),
                                              child: Padding(
                                                padding: const EdgeInsets.all(2),
                                                child: Icon(
                                                  Icons.copy_rounded,
                                                  size: 17,
                                                  color: const Color(0xFF5E7388).withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _showToast
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: AnimatedOpacity(
                            opacity: _showToast ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: AppToast(
                              message: AppLocalizations.of(context)!.copiedToClipboard,
                              leading: Image.asset(
                                'assets/app_logo.png',
                                width: 18,
                                height: 18,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                AiChefChatPopupComposer(
                  controller: _questionController,
                  isAwaitingResponse: _isAwaitingResponse,
                  isCheckingInitialConnection: _isCheckingInitialConnection,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasClearableHistory {
    if (_isCheckingInitialConnection) {
      return false;
    }
    if (_messages.isEmpty) {
      return false;
    }
    if (_messages.length > 1) {
      return true;
    }

    final firstMsg = _messages.first;
    if (firstMsg.sender == ChatSender.user) {
      return true;
    }

    final l10n = AppLocalizations.of(context)!;
    final authState = ref.read(authNotifierProvider);
    final fullName = authState.fullName?.trim();
    final greeting = fullName != null && fullName.isNotEmpty
        ? l10n.aiChefGreetingWithName(fullName)
        : l10n.aiChefGreetingWithoutName;

    final offlineMsg = l10n.aiChefServiceUnavailableMessage;

    if (firstMsg.text == greeting ||
        firstMsg.text == offlineMsg ||
        firstMsg.kind == ChatMessageKind.connectionChecking) {
      return false;
    }

    return true;
  }

  Future<void> _performClearChatHistory() async {
    final l10n = AppLocalizations.of(context)!;

    await showDeleteConfirmationDialog(
      context,
      message: l10n.clearChatHistoryConfirm,
      onDelete: () async {
        if (!mounted) {
          return;
        }

        var isDeleting = true;
        var deleteSucceeded = false;
        String? deleteErrorMessage;

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final dialogL10n = AppLocalizations.of(dialogContext)!;

            return StatefulBuilder(
              builder: (ctx, setDialogState) {
                if (isDeleting) {
                  Future.microtask(() async {
                    try {
                      final success = await widget.chatService.clearChatHistory(
                        pageContext: _normalizedPageContext,
                        recipeId: widget.recipeId,
                      );
                      deleteSucceeded = success;
                      if (!success) {
                        deleteErrorMessage = dialogL10n.clearChatHistoryError;
                      }
                      if (dialogContext.mounted) {
                        setDialogState(() {
                          isDeleting = false;
                        });
                      }
                      if (success && mounted) {
                        final authState = ref.read(authNotifierProvider);
                        final fullName = authState.fullName?.trim();
                        final greeting = fullName != null && fullName.isNotEmpty
                            ? dialogL10n.aiChefGreetingWithName(fullName)
                            : dialogL10n.aiChefGreetingWithoutName;

                        setState(() {
                          _messages.clear();
                          _messages.add(ChatMessage.text(greeting));
                        });
                      }
                    } catch (error) {
                      deleteSucceeded = false;
                      deleteErrorMessage = dialogL10n.clearChatHistoryError;
                      if (dialogContext.mounted) {
                        setDialogState(() {
                          isDeleting = false;
                        });
                      }
                    }
                  });
                }

                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Center(
                    child: DeletingStatusCard(
                      isDeleting: isDeleting,
                      deleteSucceeded: deleteSucceeded,
                      deleteErrorMessage: deleteErrorMessage,
                      deletingMessage: dialogL10n.clearingChatHistory,
                      deletedMessage: dialogL10n.chatHistoryCleared,
                      onOk: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _refreshConnectionStatus() async {
    if (_isRefreshingConnection) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isRefreshingConnection = true;
    });

    final isOnline = await widget.chatService.pingService();
    if (!mounted) {
      return;
    }

    setState(() {
      _isServiceOnline = isOnline;
      _isRefreshingConnection = false;
    });

    if (!isOnline) {
      return;
    }

    setState(() {
      _messages.add(ChatMessage.text(l10n.aiChefConnectionRestoredMessage));
    });
    _scrollToBottom();
  }

  void _openRecipeDetailsFromSearch(Map<String, dynamic> recipeJson) {
    final recipe = RecipeModel.fromJson(recipeJson);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailsPage(initialRecipe: recipe),
      ),
    );
  }

  void addRecipeSavedConfirmation(String recipeName) {
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _messages.add(
        ChatMessage.text(l10n.aiChefRecipeSavedConfirmation(recipeName)),
      );
    });
    _scrollToBottom();
  }

  void _navigateToShoppingList() {
    Navigator.of(context).pop();
    Navigator.of(context).popUntil((route) => route.isFirst);
    ref.invalidate(shoppingListItemsProvider);
    ref.read(homeTabIndexProvider.notifier).setIndex(4);
  }
}
