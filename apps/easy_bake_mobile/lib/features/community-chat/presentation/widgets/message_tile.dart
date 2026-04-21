import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/models.dart';
import 'chat_avatar.dart';

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
    final avatarColor = isCurrentUser ? const Color(0xFF1565C0) : const Color(0xFFE65100);
    final avatarIcon = isCurrentUser ? Icons.person : Icons.groups;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 4),
              child: ChatAvatar(color: avatarColor, icon: avatarIcon),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 10),
                    child: Text(
                      message.userFullName ?? message.userEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667C8E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? const Color(0xFFDCEDFE) : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isCurrentUser ? 16 : 4),
                      topRight: Radius.circular(isCurrentUser ? 4 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: isCurrentUser ? const Color(0xFF111B26) : const Color(0xFF111B26),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 10, right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF99A3AF),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        if (message.isPending)
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF99A3AF)),
                            ),
                          )
                        else
                          const Icon(
                            Icons.done_all,
                            size: 14,
                            color: Color(0xFF1565C0),
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
              padding: const EdgeInsets.only(left: 10, bottom: 4),
              child: ChatAvatar(color: avatarColor, icon: avatarIcon),
            ),
        ],
      ),
    );
  }
}
