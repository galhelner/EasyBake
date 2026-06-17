import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../recipes/domain/models/recipe_model.dart';
import '../../../recipes/presentation/pages/recipe_details_page.dart';
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
  bool _isAwaitingResponse = false;
  bool _isServiceOnline = false;
  bool _isRefreshingConnection = false;
  bool _isCheckingInitialConnection = true;
  int? _typingMessageIndex;
  int? _activeStreamingMessageIndex;
  bool _recipeIntentAnnounced = false;

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
    _initializeConnectionState();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
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

    setState(() {
      _isServiceOnline = isOnline;
      _isCheckingInitialConnection = false;
      _messages
        ..clear()
        ..add(
          isOnline
              ? ChatMessage.text(greeting)
              : ChatMessage.text(l10n.aiChefServiceUnavailableMessage),
        );
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
      _activeStreamingMessageIndex = null;
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
          if (_activeStreamingMessageIndex == null) {
            _messages.add(const ChatMessage.text(''));
            _activeStreamingMessageIndex = _messages.length - 1;
          }

          final index = _activeStreamingMessageIndex!;
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
            _messages.add(ChatMessage.text(l10n.aiChefCreatingRecipeMessage));
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
            _messages.add(
              ChatMessage.text(l10n.aiChefAddingToShoppingListMessage),
            );
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
          _activeStreamingMessageIndex = null;
          _messages.add(
            ChatMessage.recipePreview(
              recipeTitle: recipeTitle,
              imageUrl: imageUrl,
              recipePayload: recipe,
            ),
          );
          _recipeIntentAnnounced = false;
          _isAwaitingResponse = false;
        });
        _scrollToBottom();
      case ChatEventType.shoppingListAdded:
        final items = event.shoppingListItems;
        setState(() {
          _isServiceOnline = true;
          _removeTypingIndicator();
          _activeStreamingMessageIndex = null;
          _messages.add(
            ChatMessage.shoppingListAdded(
              items: items != null ? List<String>.from(items) : const [],
            ),
          );
          _recipeIntentAnnounced = false;
          _isAwaitingResponse = false;
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
          if (_activeStreamingMessageIndex != null &&
              _activeStreamingMessageIndex! < _messages.length) {
            final existing = _messages[_activeStreamingMessageIndex!];
            _messages[_activeStreamingMessageIndex!] = existing.copyWith(
              recipes: recipes,
            );
          } else {
            _messages.add(ChatMessage.searchResults(recipes: recipes));
          }
          _activeStreamingMessageIndex = null;
          _isAwaitingResponse = false;
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
          _activeStreamingMessageIndex = null;
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
          _messages.add(
            ChatMessage.swapSummary(
              title: l10n.aiChefSuggestedSubstitutionsTitle,
              swaps: swapSuggestions,
            ),
          );
        });
        _scrollToBottom();
        return;
      case ChatEventType.done:
        setState(() {
          _removeTypingIndicator();
          _normalizeActiveStreamingMessage();
          _activeStreamingMessageIndex = null;
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

  void _normalizeActiveStreamingMessage() {
    final index = _activeStreamingMessageIndex;
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

    if (_activeStreamingMessageIndex != null &&
        _activeStreamingMessageIndex! > typingIndex) {
      _activeStreamingMessageIndex = _activeStreamingMessageIndex! - 1;
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
                                    child: ChatMessageBuilder(
                                      message: message,
                                      onOpenRecipe: () {
                                        final payload = message.recipePayload;
                                        if (payload == null) {
                                          return;
                                        }
                                        widget.onOpenRecipeCreated(payload);
                                      },
                                      onRecipeTap: _openRecipeDetailsFromSearch,
                                      onNavigateToShoppingList:
                                          _navigateToShoppingList,
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
