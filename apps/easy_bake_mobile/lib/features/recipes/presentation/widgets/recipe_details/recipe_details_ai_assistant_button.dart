import 'package:flutter/material.dart';

import '../../../../ai-chat/presentation/widgets/ai_chef_chat_bubble.dart';
import 'recipe_details_theme.dart';

class RecipeDetailsAiAssistantButton extends StatelessWidget {
  const RecipeDetailsAiAssistantButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: 0, bottom: 72, child: const AiChefChatBubble()),
          Material(
            color: Colors.white,
            shape: CircleBorder(
              side: BorderSide(
                color: const Color(0xFF2E4E69).withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: Image.asset(
                  kRecipeDetailsLogoAssetPath,
                  width: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
