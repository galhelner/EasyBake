import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/models.dart';
import 'chat_avatar.dart';

Color _resolveSenderAccentColor(ChatMessage message, {required bool isCurrentUser}) {
  if (isCurrentUser) {
    return const Color(0xFF1565C0);
  }

  // Keep color stable per sender so each participant is easy to recognize.
  final senderKey = message.userId.trim().isNotEmpty
      ? message.userId.trim()
      : (message.userEmail.trim().isNotEmpty
            ? message.userEmail.trim().toLowerCase()
            : (message.userFullName?.trim().toLowerCase() ?? 'baker'));

  const palette = <Color>[
    Color(0xFF00897B),
    Color(0xFF6D4C41),
    Color(0xFF7B1FA2),
    Color(0xFFC62828),
    Color(0xFF2E7D32),
    Color(0xFF5D4037),
    Color(0xFFEF6C00),
    Color(0xFFAD1457),
    Color(0xFF455A64),
    Color(0xFF9E9D24),
  ];

  final hash = senderKey.codeUnits.fold<int>(0, (value, unit) => value * 31 + unit);
  return palette[hash.abs() % palette.length];
}

class MessageTile extends StatelessWidget {
  const MessageTile({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  final ChatMessage message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final avatarColor = _resolveSenderAccentColor(
      message,
      isCurrentUser: isCurrentUser,
    );
    final avatarIcon = isCurrentUser ? Icons.person : Icons.groups;
    final senderName = (message.userFullName?.trim().isNotEmpty ?? false)
        ? message.userFullName!.trim()
        : (message.userEmail.isNotEmpty ? message.userEmail : 'Baker');
    const avatarSlotWidth = 54.0;
    const avatarGap = 10.0;
    const incomingBubbleTopOffset = 6.0;
    const currentUserBubbleTopOffset = 24.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCurrentUser)
                SizedBox(
                  width: avatarSlotWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChatAvatar(color: avatarColor, icon: avatarIcon),
                    ],
                  ),
                ),
              if (!isCurrentUser) const SizedBox(width: avatarGap),
              Padding(
                padding: EdgeInsets.only(
                  top: isCurrentUser
                      ? currentUserBubbleTopOffset
                      : incomingBubbleTopOffset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  child: _BubbleShell(
                    isCurrentUser: isCurrentUser,
                    color: isCurrentUser
                        ? const Color(0xFFDCEDFE)
                        : const Color(0xFFE8E8E8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isCurrentUser) ...[
                          Text(
                            senderName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.2,
                              color: avatarColor.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          message.content,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Color(0xFF111B26),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(message.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6E8298),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 5),
                              if (message.isPending)
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6E8298),
                                    ),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.done,
                                  size: 13,
                                  color: Color(0xFF1D67C2),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isCurrentUser) const SizedBox(width: avatarGap),
              if (isCurrentUser)
                SizedBox(
                  width: avatarSlotWidth,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ChatAvatar(color: avatarColor, icon: avatarIcon),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _BubbleShell extends StatelessWidget {
  const _BubbleShell({
    required this.isCurrentUser,
    required this.color,
    required this.child,
  });

  final bool isCurrentUser;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isCurrentUser ? 18 : 4),
              topRight: Radius.circular(isCurrentUser ? 4 : 18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}
