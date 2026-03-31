import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/services/chat_service.dart';

Future<void> showAiChefChatPopup(
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
      pageContext: pageContext,
      recipeId: recipeId,
      chatService: chatService,
      onOpenRecipeCreated: onOpenRecipeCreated,
    ),
  );
}

class _AiChefChatPopupDialog extends StatefulWidget {
  const _AiChefChatPopupDialog({
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
  State<_AiChefChatPopupDialog> createState() => _AiChefChatPopupDialogState();
}

class _AiChefChatPopupDialogState extends State<_AiChefChatPopupDialog> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage.connectionChecking(),
  ];

  StreamSubscription<ChatEvent>? _chatSubscription;
  bool _isAwaitingResponse = false;
  bool _isServiceOnline = false;
  bool _isRefreshingConnection = false;
  bool _isCheckingInitialConnection = true;
  int? _typingMessageIndex;
  int? _activeStreamingMessageIndex;

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

    final authState = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authNotifierProvider);
    final displayName = authState.displayName?.trim();
    final greeting = displayName != null && displayName.isNotEmpty
        ? 'Hello $displayName!\nHow can I help you?'
        : 'How can I help you?';

    setState(() {
      _isServiceOnline = isOnline;
      _isCheckingInitialConnection = false;
      _messages
        ..clear()
        ..add(
          isOnline
              ? _ChatMessage.ai(greeting)
              : const _ChatMessage.ai(
                  'Recipe service is currently unavailable. Please tap Refresh and try again.',
                ),
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
      _messages.add(_ChatMessage.user(message));
      _messages.add(const _ChatMessage.typing());
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

    _chatSubscription = widget.chatService
        .sendPrompt(
          prompt: message,
          pageContext: contextForRequest,
          recipeId: widget.recipeId,
        )
        .listen(_handleChatEvent);
  }

  void _handleChatEvent(ChatEvent event) {
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
            _messages.add(const _ChatMessage.ai(''));
            _activeStreamingMessageIndex = _messages.length - 1;
          }

          final index = _activeStreamingMessageIndex!;
          final existing = _messages[index];
          _messages[index] = existing.copyWith(text: '${existing.text}$delta');
        });
        _scrollToBottom();
      case ChatEventType.recipeCreated:
        final recipe = event.recipe;
        final recipeTitle = recipe?['title']?.toString() ?? 'your recipe';

        setState(() {
          _isServiceOnline = true;
          _removeTypingIndicator();
          _activeStreamingMessageIndex = null;
          _messages.add(
            _ChatMessage.ai('Your recipe "$recipeTitle" is ready.'),
          );
          _messages.add(
            _ChatMessage.recipeCta(
              recipeTitle: recipeTitle,
              recipePayload: recipe,
            ),
          );
          _isAwaitingResponse = false;
        });
        _scrollToBottom();
      case ChatEventType.error:
        final errorMessage =
            event.message ?? 'Something went wrong while chatting.';

        setState(() {
          _isServiceOnline = !event.isConnectionIssue;
          _removeTypingIndicator();
          _activeStreamingMessageIndex = null;
          _messages.add(_ChatMessage.ai(errorMessage));
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
            _ChatMessage.swapSummary(
              title: 'Suggested substitutions',
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
          _isAwaitingResponse = false;
        });
        _scrollToBottom();
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
    if (existing.kind != _ChatMessageKind.text) {
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
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEAF2F5), Color(0xFFDCE8EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: Color(0xFFD0DCE3))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFBFD0D9)),
                      ),
                      child: Image.asset(
                        'assets/ai_chef_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EasyBake AI Chef',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF253852),
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chat assistant',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF557089),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isCheckingInitialConnection
                              ? const Color(0xFFD3DADF)
                              : _isServiceOnline
                              ? const Color(0xFFBDD0DC)
                              : const Color(0xFFE8B8B8),
                        ),
                      ),
                      child: Text(
                        _isCheckingInitialConnection
                            ? 'Checking...'
                            : _isServiceOnline
                            ? 'Online'
                            : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isCheckingInitialConnection
                              ? const Color(0xFF6A7884)
                              : _isServiceOnline
                              ? const Color(0xFF2D6680)
                              : const Color(0xFFB93838),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!_isServiceOnline && !_isCheckingInitialConnection) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          onPressed: _isRefreshingConnection
                              ? null
                              : _refreshConnectionStatus,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDAA4A4)),
                            foregroundColor: const Color(0xFFB93838),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: _isRefreshingConnection
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: Color(0xFFB93838),
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text(
                            'Refresh',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF3C536B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isAi = message.sender == _ChatSender.ai;

                      return Align(
                        alignment: isAi
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: isAi
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isAi)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 8,
                                  top: 4,
                                ),
                                child: Image.asset(
                                  'assets/ai_chef_logo.png',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            Flexible(
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
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(isAi ? 3 : 12),
                                    topRight: Radius.circular(isAi ? 12 : 3),
                                    bottomLeft: const Radius.circular(12),
                                    bottomRight: const Radius.circular(12),
                                  ),
                                ),
                                child: _buildMessageBody(message),
                              ),
                            ),
                            if (!isAi)
                              const Padding(
                                padding: EdgeInsets.only(left: 8, top: 2),
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFF2B3D5A),
                                  size: 22,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: TextField(
                          controller: _questionController,
                          enabled:
                              !_isAwaitingResponse &&
                              !_isCheckingInitialConnection,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Ask a Question',
                            hintStyle: TextStyle(color: Color(0xFF706C6C)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: Color(0xFF2B3D5A)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: Color(0xFF2B3D5A)),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed:
                          _isAwaitingResponse || _isCheckingInitialConnection
                          ? null
                          : _sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Color(0xFF2B3D5A),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshConnectionStatus() async {
    if (_isRefreshingConnection) {
      return;
    }

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
      _messages.add(
        const _ChatMessage.ai(
          'Connection restored. You can continue chatting.',
        ),
      );
    });
    _scrollToBottom();
  }

  Widget _buildMessageBody(_ChatMessage message) {
    switch (message.kind) {
      case _ChatMessageKind.typing:
        return const _TypingDots();
      case _ChatMessageKind.recipeCta:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recipe created: ${message.recipeTitle ?? 'Untitled'}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                final payload = message.recipePayload;
                if (payload == null) {
                  return;
                }

                Navigator.of(context).pop();
                widget.onOpenRecipeCreated(payload);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2B3D5A)),
                foregroundColor: const Color(0xFF2B3D5A),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('View recipe created'),
            ),
          ],
        );
      case _ChatMessageKind.connectionChecking:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync, size: 15, color: Color(0xFF3A5670)),
            SizedBox(width: 8),
            _TypingDots(),
          ],
        );
      case _ChatMessageKind.swapSummary:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8FC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC5DAE8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: Color(0xFF2B5D7A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.title ?? 'Suggested substitutions',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF21445A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...message.swaps!.map(
                (swap) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSwapLine(swap),
                ),
              ),
            ],
          ),
        );
      case _ChatMessageKind.text:
        return Text(
          message.text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            height: 1.35,
          ),
        );
    }
  }

  Widget _buildSwapLine(String rawSwap) {
    final swap = rawSwap.trim();
    final parsed = _parseSwapPair(swap);

    if (parsed == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD2E1EB)),
        ),
        child: Text(
          swap,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF17364A),
            height: 1.25,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD2E1EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              parsed.$1,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF335A70),
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: Color(0xFF2B5D7A),
            ),
          ),
          Expanded(
            child: Text(
              parsed.$2,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF17364A),
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, String)? _parseSwapPair(String swap) {
    final separators = ['->', '=>', '→', ' to '];

    for (final separator in separators) {
      final index = separator == ' to '
          ? swap.toLowerCase().indexOf(separator)
          : swap.indexOf(separator);

      if (index <= 0) {
        continue;
      }

      final left = swap.substring(0, index).trim();
      final right = swap.substring(index + separator.length).trim();
      if (left.isEmpty || right.isEmpty) {
        continue;
      }

      return (left, right);
    }

    return null;
  }
}

enum _ChatSender { ai, user }

class _ChatMessage {
  const _ChatMessage._({
    required this.text,
    required this.sender,
    required this.kind,
    this.recipeTitle,
    this.recipePayload,
    this.title,
    this.swaps,
  });

  const _ChatMessage.ai(String text)
    : this._(text: text, sender: _ChatSender.ai, kind: _ChatMessageKind.text);

  const _ChatMessage.user(String text)
    : this._(text: text, sender: _ChatSender.user, kind: _ChatMessageKind.text);

  const _ChatMessage.typing()
    : this._(text: '', sender: _ChatSender.ai, kind: _ChatMessageKind.typing);

  const _ChatMessage.connectionChecking()
    : this._(
        text: '',
        sender: _ChatSender.ai,
        kind: _ChatMessageKind.connectionChecking,
      );

  const _ChatMessage.recipeCta({
    required String recipeTitle,
    Map<String, dynamic>? recipePayload,
  }) : this._(
         text: '',
         sender: _ChatSender.ai,
         kind: _ChatMessageKind.recipeCta,
         recipeTitle: recipeTitle,
         recipePayload: recipePayload,
       );

  const _ChatMessage.swapSummary({
    required String title,
    required List<String> swaps,
  }) : this._(
         text: '',
         sender: _ChatSender.ai,
         kind: _ChatMessageKind.swapSummary,
         title: title,
         swaps: swaps,
       );

  final String text;
  final _ChatSender sender;
  final _ChatMessageKind kind;
  final String? recipeTitle;
  final Map<String, dynamic>? recipePayload;
  final String? title;
  final List<String>? swaps;

  _ChatMessage copyWith({String? text}) {
    return _ChatMessage._(
      text: text ?? this.text,
      sender: sender,
      kind: kind,
      recipeTitle: recipeTitle,
      recipePayload: recipePayload,
      title: title,
      swaps: swaps,
    );
  }
}

enum _ChatMessageKind {
  text,
  typing,
  connectionChecking,
  recipeCta,
  swapSummary,
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0.0),
            const SizedBox(width: 5),
            _dot(0.33),
            const SizedBox(width: 5),
            _dot(0.66),
          ],
        );
      },
    );
  }

  Widget _dot(double phase) {
    final value = _controller.value;
    var distance = (value - phase).abs();
    if (distance > 0.5) {
      distance = 1 - distance;
    }

    final opacity = (1 - (distance * 2)).clamp(0.25, 1.0);

    return Opacity(
      opacity: opacity,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF3A5670),
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 8, height: 8),
      ),
    );
  }
}
