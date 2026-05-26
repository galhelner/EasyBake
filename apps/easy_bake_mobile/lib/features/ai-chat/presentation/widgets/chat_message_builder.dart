import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'ai_chef_chat_typing_dots.dart';
import 'ai_chef_connection_checking.dart';
import 'ai_chef_message_text.dart';
import 'ai_chef_recipe_preview.dart';
import 'ai_chef_search_results.dart';
import 'ai_chef_swap_summary.dart';

/// Enum for different chat message types
enum ChatMessageKind {
  text,
  typing,
  connectionChecking,
  recipePreview,
  swapSummary,
  searchResults,
}

/// Enum for message sender
enum ChatSender { ai, user }

/// Data model for a chat message
class ChatMessage {
  const ChatMessage._({
    required this.text,
    required this.kind,
    required this.sender,
    this.recipeTitle,
    this.recipePayload,
    this.imageUrl,
    this.title,
    this.swaps,
    this.recipes,
  });

  const ChatMessage.text(String text, {ChatSender sender = ChatSender.ai})
      : this._(text: text, kind: ChatMessageKind.text, sender: sender);

  const ChatMessage.typing()
      : this._(text: '', kind: ChatMessageKind.typing, sender: ChatSender.ai);

  const ChatMessage.connectionChecking()
      : this._(
          text: '',
          kind: ChatMessageKind.connectionChecking,
          sender: ChatSender.ai,
        );

  const ChatMessage.recipePreview({
    required String recipeTitle,
    String? imageUrl,
    Map<String, dynamic>? recipePayload,
  }) : this._(
         text: '',
         kind: ChatMessageKind.recipePreview,
         sender: ChatSender.ai,
         recipeTitle: recipeTitle,
         imageUrl: imageUrl,
         recipePayload: recipePayload,
       );

  const ChatMessage.swapSummary({
    required String title,
    required List<String> swaps,
  }) : this._(
         text: '',
         kind: ChatMessageKind.swapSummary,
         sender: ChatSender.ai,
         title: title,
         swaps: swaps,
       );

  const ChatMessage.searchResults({required List<dynamic> recipes})
      : this._(
          text: '',
          kind: ChatMessageKind.searchResults,
          sender: ChatSender.ai,
          recipes: recipes,
        );

  final String text;
  final ChatMessageKind kind;
  final ChatSender sender;
  final String? recipeTitle;
  final Map<String, dynamic>? recipePayload;
  final String? imageUrl;
  final String? title;
  final List<String>? swaps;
  final List<dynamic>? recipes;

  ChatMessage copyWith({String? text, List<dynamic>? recipes}) {
    return ChatMessage._(
      text: text ?? this.text,
      kind: kind,
      sender: sender,
      recipeTitle: recipeTitle,
      recipePayload: recipePayload,
      imageUrl: imageUrl,
      title: title,
      swaps: swaps,
      recipes: recipes ?? this.recipes,
    );
  }
}

/// Builds the appropriate widget for a chat message based on its type
class ChatMessageBuilder extends StatelessWidget {
  const ChatMessageBuilder({
    required this.message,
    required this.onOpenRecipe,
    required this.onRecipeTap,
    super.key,
  });

  final ChatMessage message;
  final VoidCallback onOpenRecipe;
  final Function(Map<String, dynamic>) onRecipeTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (message.kind) {
      case ChatMessageKind.typing:
        return const AiChefChatTypingDots();
      case ChatMessageKind.connectionChecking:
        return const AiChefConnectionChecking();
      case ChatMessageKind.recipePreview:
        return AiChefRecipePreview(
          recipeTitle: message.recipeTitle ?? l10n.aiChefYourRecipeFallback,
          imageUrl: message.imageUrl ?? '',
          recipePayload: message.recipePayload ?? {},
          onViewRecipe: onOpenRecipe,
        );
      case ChatMessageKind.swapSummary:
        return AiChefSwapSummary(
          title: message.title ?? l10n.aiChefSuggestedSubstitutionsTitle,
          swaps: message.swaps ?? [],
        );
      case ChatMessageKind.searchResults:
      case ChatMessageKind.text when message.recipes != null:
        return AiChefSearchResults(
          message: message.text,
          recipes: message.recipes ?? [],
          onRecipeTap: onRecipeTap,
        );
      case ChatMessageKind.text:
        return AiChefMessageText(message.text);
    }
  }
}
