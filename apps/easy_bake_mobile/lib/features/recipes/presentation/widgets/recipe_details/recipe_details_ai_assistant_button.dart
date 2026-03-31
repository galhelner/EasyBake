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
            shape: const CircleBorder(
              side: BorderSide(color: Color(0xFF304466), width: 2),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap ?? () {},
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Image.asset(
                      kRecipeDetailsLogoAssetPath,
                      width: 38,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Positioned(
                    right: 14,
                    top: 10,
                    child: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFFC857),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
