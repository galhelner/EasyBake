import 'package:flutter/material.dart';

import 'ai_chef_chat_typing_dots.dart';

/// Displays the connection checking state with spinner and typing animation
class AiChefConnectionChecking extends StatelessWidget {
  const AiChefConnectionChecking({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sync, size: 15, color: Color(0xFF3A5670)),
        SizedBox(width: 8),
        AiChefChatTypingDots(),
      ],
    );
  }
}
