import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/chat_provider.dart';
import '../../domain/models/models.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

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
    final error = ref.watch(chatErrorProvider);
    final authNotifier = ref.watch(authNotifierProvider);
    final currentUserId = authNotifier.userId?.trim() ?? '';
    final currentUserEmail = authNotifier.email?.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        title: const Text(
          'Community Chat',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF20364D),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: _ConnectionPill(
                isConnecting: isConnecting,
                isConnected: isConnected,
              ),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2F6FB), Color(0xFFEAF2FA)],
          ),
        ),
        child: Column(
          children: [
            if (isConnecting)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: _StatusBanner(
                  icon: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  ),
                  text: 'Connecting to community chat...',
                  backgroundColor: const Color(0xFFE4EEF9),
                  textColor: const Color(0xFF285175),
                ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _StatusBanner(
                  icon: const Icon(Icons.error_outline, color: Color(0xFFB43B3B), size: 18),
                  text: error,
                  backgroundColor: const Color(0xFFFCECEC),
                  textColor: const Color(0xFFA12E2E),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshChat,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  itemCount: messages.isEmpty ? 1 : messages.length,
                  itemBuilder: (context, index) {
                    if (messages.isEmpty) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.52,
                        child: const _EmptyState(),
                      );
                    }

                    final message = messages[index];
                    final isCurrentUser =
                        (currentUserId.isNotEmpty && message.userId == currentUserId) ||
                        (currentUserEmail.isNotEmpty &&
                            message.userEmail.isNotEmpty &&
                            message.userEmail == currentUserEmail);

                    return _MessageTile(
                      message: message,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
              ),
            ),
            _Composer(
              controller: _messageController,
              isConnected: isConnected,
              isConnecting: isConnecting,
              onSend: _sendMessage,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({
    required this.isConnecting,
    required this.isConnected,
  });

  final bool isConnecting;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final label = isConnecting ? 'Connecting' : (isConnected ? 'Online' : 'Offline');
    final textColor = isConnecting
        ? const Color(0xFF2A5A7D)
        : (isConnected ? const Color(0xFF1E7B47) : const Color(0xFFB33A3A));
    final bgColor = isConnecting
        ? const Color(0xFFE6F0FA)
        : (isConnected ? const Color(0xFFE6F7EF) : const Color(0xFFFCECEC));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConnecting)
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.7,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  final Widget icon;
  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 34,
              color: Color(0xFF86A3C3),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A445F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start the first conversation in the room.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blueGrey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.isCurrentUser,
  });

  final ChatMessage message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final avatarColor = isCurrentUser ? const Color(0xFF2F80ED) : const Color(0xFFD7A247);
    final avatarIcon = isCurrentUser ? Icons.person : Icons.groups;
    final bubbleGradient = isCurrentUser
        ? const LinearGradient(
            colors: [Color(0xFFDAEAFF), Color(0xFFD1E4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFF8E8), Color(0xFFFFF2D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final bubbleRadius = BorderRadius.only(
      topLeft: Radius.circular(isCurrentUser ? 16 : 5),
      topRight: Radius.circular(isCurrentUser ? 5 : 16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: _ChatAvatar(color: avatarColor, icon: avatarIcon),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 6),
                    child: Text(
                      message.userFullName ?? message.userEmail,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.blueGrey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: bubbleGradient,
                    borderRadius: bubbleRadius,
                    border: Border.all(
                      color: isCurrentUser ? const Color(0xFFBFD7FC) : const Color(0xFFE6D2A6),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: isCurrentUser ? const Color(0xFF173B64) : const Color(0xFF5D4826),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        if (message.isPending)
                          SizedBox(
                            width: 11,
                            height: 11,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blueGrey.shade500,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.done,
                            size: 13,
                            color: Colors.green.shade700,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: _ChatAvatar(color: avatarColor, icon: avatarIcon),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isConnected,
    required this.isConnecting,
    required this.onSend,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isInputEmpty = controller.text.trim().isEmpty;
    final canSend = !isInputEmpty && isConnected;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCCF0F5FB), Color(0xE6E9F1FA)],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFCFDCEC).withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8FBFF), Color(0xFFEFF5FC)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFCDDCEC)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                enabled: isConnected,
                maxLines: null,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: isConnecting
                      ? 'Connecting to community chat...'
                      : (isConnected ? 'Write a message...' : 'Offline'),
                  hintStyle: TextStyle(color: Colors.blueGrey.shade300),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: canSend
                  ? const LinearGradient(
                      colors: [Color(0xFF4B92F4), Color(0xFF2F79DE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: canSend ? null : const Color(0xFFD2DDEB),
              boxShadow: canSend
                  ? const [
                      BoxShadow(
                        color: Color(0x303774D0),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: canSend ? onSend : null,
              icon: Icon(
                Icons.send_rounded,
                color: canSend ? Colors.white : Colors.blueGrey.shade300,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}
