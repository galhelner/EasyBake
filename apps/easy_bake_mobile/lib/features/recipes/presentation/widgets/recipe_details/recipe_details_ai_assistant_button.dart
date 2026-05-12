import 'package:flutter/material.dart';

import '../ai_chef_chat_button.dart';
import 'recipe_details_theme.dart';

class RecipeDetailsAiAssistantButton extends StatelessWidget {
  const RecipeDetailsAiAssistantButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AiChefChatButton(
      onTap: onTap,
      logoAssetPath: kRecipeDetailsLogoAssetPath,
    );
  }
}
