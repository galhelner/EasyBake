import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'ai_chef_chat_typing_dots.dart';
import 'ai_chef_connection_checking.dart';
import 'ai_chef_message_text.dart';
import 'ai_chef_recipe_preview.dart';
import 'ai_chef_search_results.dart';
import 'ai_chef_swap_summary.dart';
import 'ai_chef_shopping_list_added.dart';

/// Enum for different chat message types
enum ChatMessageKind {
  text,
  typing,
  connectionChecking,
  recipePreview,
  swapSummary,
  searchResults,
  shoppingListAdded,
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
    this.shoppingListItems,
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

  const ChatMessage.shoppingListAdded({required List<String> items})
      : this._(
          text: '',
          kind: ChatMessageKind.shoppingListAdded,
          sender: ChatSender.ai,
          shoppingListItems: items,
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
  final List<String>? shoppingListItems;

  ChatMessage copyWith({
    String? text,
    ChatMessageKind? kind,
    ChatSender? sender,
    String? recipeTitle,
    Map<String, dynamic>? recipePayload,
    String? imageUrl,
    String? title,
    List<String>? swaps,
    List<dynamic>? recipes,
    List<String>? shoppingListItems,
  }) {
    return ChatMessage._(
      text: text ?? this.text,
      kind: kind ?? this.kind,
      sender: sender ?? this.sender,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      recipePayload: recipePayload ?? this.recipePayload,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      swaps: swaps ?? this.swaps,
      recipes: recipes ?? this.recipes,
      shoppingListItems: shoppingListItems ?? this.shoppingListItems,
    );
  }
}

/// Builds the appropriate widget for a chat message based on its type
class ChatMessageBuilder extends StatelessWidget {
  const ChatMessageBuilder({
    required this.message,
    required this.onOpenRecipe,
    required this.onRecipeTap,
    this.onNavigateToShoppingList,
    super.key,
  });

  final ChatMessage message;
  final VoidCallback onOpenRecipe;
  final Function(Map<String, dynamic>) onRecipeTap;
  final VoidCallback? onNavigateToShoppingList;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (message.kind) {
      case ChatMessageKind.typing:
        return const AiChefChatTypingDots();
      case ChatMessageKind.connectionChecking:
        return const AiChefConnectionChecking();
      case ChatMessageKind.recipePreview:
        final previewWidget = AiChefRecipePreview(
          recipeTitle: message.recipeTitle ?? l10n.aiChefYourRecipeFallback,
          imageUrl: message.imageUrl ?? '',
          recipePayload: message.recipePayload ?? {},
          onViewRecipe: onOpenRecipe,
        );
        if (message.text.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AiChefMessageText(message.text),
              const SizedBox(height: 12),
              previewWidget,
            ],
          );
        }
        return previewWidget;
      case ChatMessageKind.swapSummary:
        final swapWidget = AiChefSwapSummary(
          title: message.title ?? l10n.aiChefSuggestedSubstitutionsTitle,
          swaps: message.swaps ?? [],
        );
        if (message.text.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AiChefMessageText(message.text),
              const SizedBox(height: 12),
              swapWidget,
            ],
          );
        }
        return swapWidget;
      case ChatMessageKind.searchResults:
        return AiChefSearchResults(
          message: message.text,
          recipes: message.recipes ?? [],
          onRecipeTap: onRecipeTap,
        );
      case ChatMessageKind.shoppingListAdded:
        final shoppingWidget = AiChefShoppingListAdded(
          items: message.shoppingListItems ?? [],
          onNavigateToShoppingList: onNavigateToShoppingList ?? () {},
        );
        if (message.text.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AiChefMessageText(message.text),
              const SizedBox(height: 12),
              shoppingWidget,
            ],
          );
        }
        return shoppingWidget;
      case ChatMessageKind.text:
        if (message.text.isEmpty) {
          return const AiChefChatTypingDots();
        }
        return AiChefMessageText(message.text);
    }
  }
}
