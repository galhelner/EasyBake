import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../home/presentation/pages/home_tabs_page.dart';
import '../widgets/connection_pill.dart';
import '../widgets/empty_state.dart';
import '../widgets/message_tile.dart';
import '../widgets/composer.dart';
import '../widgets/share_recipe_dialog.dart';

class CommunityChat extends ConsumerStatefulWidget {
  const CommunityChat({super.key});

  @override
  ConsumerState<CommunityChat> createState() => _CommunityChatState();
}

class _CommunityChatState extends ConsumerState<CommunityChat> {
  late TextEditingController _messageController;
  final _scrollController = ScrollController();
  bool _isFailureDialogOpen = false;

  /// Cached so [dispose] never calls `ref.read` after the element is unmounted.
  late final ChatServiceNotifier _chatServiceNotifier;

  @override
  void initState() {
    super.initState();
    _messageController = MentionTextEditingController();
    _chatServiceNotifier = ref.read(chatServiceProvider.notifier);
    Future.microtask(() {
      if (ref.read(homeTabIndexProvider) == 1) {
        _initializeChat();
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();

    if (_messageController is! MentionTextEditingController) {
      final previousController = _messageController;
      final updatedController = MentionTextEditingController();
      updatedController.value = previousController.value;
      _messageController = updatedController;
      previousController.dispose();
      setState(() {});
    }
  }

  Future<void> _initializeChat() async {
    ref.read(chatErrorProvider.notifier).setError(null);
    await _chatServiceNotifier.initializeChat();
  }

  Future<void> _refreshChat() async {
    ref.read(chatErrorProvider.notifier).setError(null);
    await _chatServiceNotifier.refreshMessages();
  }

  Future<void> _showShareRecipeDialog() async {
    if (!mounted) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => ShareRecipeDialog(
        onRecipeSelected: (recipeId) {
          _chatServiceNotifier.sendRecipeMessage(recipeId);
          _scrollToBottom();
        },
      ),
    );

    if (mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _showChatFailureDialog(String message) async {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted || _isFailureDialogOpen) {
      return;
    }

    _isFailureDialogOpen = true;

    final shouldRefresh =
        ref.read(chatConnectionStateProvider) == ChatConnectionState.connected;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, color: Color(0xFFB43B3B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.communityChatUnavailableTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Text('$message\n\n${l10n.communityChatFailureHint}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.laterButtonLabel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (shouldRefresh) {
                    unawaited(_refreshChat());
                  } else {
                    unawaited(_initializeChat());
                  }
                },
                child: Text(
                  shouldRefresh
                      ? l10n.refreshButtonLabel
                      : l10n.tryAgainButtonLabel,
                ),
              ),
            ],
          );
        },
      );
    } finally {
      _isFailureDialogOpen = false;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    unawaited(_chatServiceNotifier.dispose());
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _chatServiceNotifier.sendMessage(content);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messages = ref.watch(chatMessagesProvider);
    final connectionState = ref.watch(chatConnectionStateProvider);
    final isConnected = connectionState == ChatConnectionState.connected;
    final isConnecting = connectionState == ChatConnectionState.connecting;
    final authNotifier = ref.watch(authNotifierProvider);
    final currentUserId = authNotifier.userId?.trim() ?? '';
    final currentUserEmail = authNotifier.email?.trim() ?? '';

    ref.listen<int>(homeTabIndexProvider, (previous, next) {
      if (next == 1 &&
          ref.read(chatConnectionStateProvider) ==
              ChatConnectionState.disconnected) {
        _initializeChat();
      }
    });

    ref.listen<String?>(chatErrorProvider, (previous, next) {
      if (next == null || next == previous) {
        return;
      }

      if (ref.read(homeTabIndexProvider) != 1) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _showChatFailureDialog(next);
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: const Color(0xFFFCFDFE),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: const Color(0xFFCFDBE8).withValues(alpha: 0.7),
          ),
        ),
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: Image.asset(
                'assets/app_logo_full.png',
                fit: BoxFit.fitHeight,
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.communityChatHeaderTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF111B26),
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    l10n.communityChatHeaderSubtitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF667C8E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              child: ConnectionPill(
                isConnecting: isConnecting,
                isConnected: isConnected,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF2F6FB), Color(0xFFEAF1F9)],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshChat,
                  color: const Color(0xFF1565C0),
                  backgroundColor: Colors.white,
                  child: ListView.builder(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    itemCount: messages.isEmpty ? 1 : messages.length,
                    itemBuilder: (context, index) {
                      if (messages.isEmpty) {
                        final isOffline =
                            connectionState == ChatConnectionState.disconnected;

                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: EmptyState(isOffline: isOffline),
                        );
                      }

                      final message = messages[index];
                      final isCurrentUser =
                          (currentUserId.isNotEmpty &&
                              message.userId == currentUserId) ||
                          (currentUserEmail.isNotEmpty &&
                              message.userEmail.isNotEmpty &&
                              message.userEmail == currentUserEmail);

                      return MessageTile(
                        key: ValueKey(message.id),
                        message: message,
                        isCurrentUser: isCurrentUser,
                      );
                    },
                  ),
                ),
              ),
              Composer(
                controller: _messageController,
                isConnected: isConnected,
                isConnecting: isConnecting,
                onSend: _sendMessage,
                onShareRecipe: _showShareRecipeDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
