import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../widgets/connection_pill.dart';
import '../widgets/status_banner.dart';
import '../widgets/empty_state.dart';
import '../widgets/message_tile.dart';
import '../widgets/composer.dart';

class CommunityChat extends ConsumerStatefulWidget {
  const CommunityChat({super.key});

  @override
  ConsumerState<CommunityChat> createState() => _CommunityChatState();
}

class _CommunityChatState extends ConsumerState<CommunityChat> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    await ref.read(chatServiceProvider.notifier).initializeChat();
  }

  Future<void> _refreshChat() async {
    await ref.read(chatServiceProvider.notifier).refreshMessages();
  }

  Future<void> _showChatFailureDialog(String message) async {
    if (!mounted) {
      return;
    }

    final shouldRefresh = ref.read(chatConnectionStateProvider) == ChatConnectionState.connected;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: Color(0xFFB43B3B)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Community chat is unavailable',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            '$message\n\nYou can try again later or refresh the chat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Later'),
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
              child: Text(shouldRefresh ? 'Refresh' : 'Try again'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    ref.read(chatServiceProvider.notifier).dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref.read(chatServiceProvider.notifier).sendMessage(content);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final connectionState = ref.watch(chatConnectionStateProvider);
    final isConnected = connectionState == ChatConnectionState.connected;
    final isConnecting = connectionState == ChatConnectionState.connecting;
    final authNotifier = ref.watch(authNotifierProvider);
    final currentUserId = authNotifier.userId?.trim() ?? '';
    final currentUserEmail = authNotifier.email?.trim() ?? '';

    ref.listen<String?>(chatErrorProvider, (previous, next) {
      if (next == null || next == previous) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _showChatFailureDialog(next);
        ref.read(chatErrorProvider.notifier).setError(null);
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.grey.shade50,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: AssetImage('assets/app_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Community Chat',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF111B26),
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Bakers Community',
                    style: TextStyle(
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
            padding: const EdgeInsets.only(right: 16),
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
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              if (isConnecting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: StatusBanner(
                    icon: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A5A7D)),
                      ),
                    ),
                    text: 'Connecting...',
                    backgroundColor: const Color(0xFFE3F2FD),
                    textColor: const Color(0xFF1565C0),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshChat,
                  color: const Color(0xFF1565C0),
                  backgroundColor: Colors.white,
                  child: ListView.builder(
                    controller: _scrollController,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: messages.isEmpty ? 1 : messages.length,
                    itemBuilder: (context, index) {
                      if (messages.isEmpty) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const EmptyState(),
                        );
                      }

                      final message = messages[index];
                      final isCurrentUser =
                          (currentUserId.isNotEmpty && message.userId == currentUserId) ||
                          (currentUserEmail.isNotEmpty &&
                              message.userEmail.isNotEmpty &&
                              message.userEmail == currentUserEmail);

                      return MessageTile(
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
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
