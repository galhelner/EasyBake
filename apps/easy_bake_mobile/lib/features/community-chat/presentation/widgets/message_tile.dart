import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../domain/models/models.dart';
import '../providers/chat_provider.dart';
import '../../../recipes/presentation/pages/recipe_details_page.dart';
import '../../../recipes/data/services/recipe_service.dart';
import '../../../recipes/presentation/providers/recipe_providers.dart';
import '../../../recipes/presentation/widgets/recipe_details/saving_status_card.dart';
import '../../../recipes/domain/models/recipe_model.dart';
import '../../../ai-chat/presentation/widgets/ai_chef_chat_typing_dots.dart';
import '../../../ai-chat/presentation/widgets/ai_chef_recipe_preview.dart';
import 'chat_avatar.dart';
import 'shared_recipe_preview_card.dart';

String _userFacingRecipeSaveError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is String && err.trim().isNotEmpty) {
        return err.trim();
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }
  }
  return 'Could not save recipe. Please try again.';
}

Color _resolveSenderAccentColor(
  ChatMessage message, {
  required bool isCurrentUser,
}) {
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

  final hash = senderKey.codeUnits.fold<int>(
    0,
    (value, unit) => value * 31 + unit,
  );
  return palette[hash.abs() % palette.length];
}

const Color _aiChefAvatarBackgroundColor = Color(0xFFF3F7FA);
const Color _aiChefAvatarBorderColor = Color(0xFFB8CAD8);

TextSpan _buildCommunityChatTextSpan(String text, TextStyle baseStyle) {
  const mention = '@aichef';
  final mentionStyle = baseStyle.copyWith(
    color: const Color(0xFF1F6FC9),
    fontWeight: FontWeight.w700,
  );

  if (text.isEmpty) {
    return TextSpan(style: baseStyle, text: text);
  }

  final spans = <InlineSpan>[];
  var index = 0;

  while (index < text.length) {
    final mentionIndex = text.toLowerCase().indexOf(mention, index);
    if (mentionIndex == -1) {
      spans.add(TextSpan(text: text.substring(index)));
      break;
    }

    if (mentionIndex > index) {
      spans.add(TextSpan(text: text.substring(index, mentionIndex)));
    }

    spans.add(
      TextSpan(
        text: text.substring(mentionIndex, mentionIndex + mention.length),
        style: mentionStyle,
      ),
    );
    index = mentionIndex + mention.length;
  }

  return TextSpan(style: baseStyle, children: spans);
}

class MessageTile extends ConsumerWidget {
  const MessageTile({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  final ChatMessage message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAiAssistant =
        message.type == ChatMessageType.aiAssistant ||
        message.type == ChatMessageType.recipePreview ||
        message.userId == 'ai-chef';
    final avatarColor = _resolveSenderAccentColor(
      message,
      isCurrentUser: isCurrentUser,
    );
    final avatarBackgroundColor = isAiAssistant
        ? _aiChefAvatarBackgroundColor
        : avatarColor;
    final avatarIcon = isCurrentUser
        ? Icons.person
        : (isAiAssistant ? Icons.smart_toy_rounded : Icons.groups);
    final avatarImageAsset = isAiAssistant ? 'assets/ai_chef_logo.png' : null;
    final senderName = (message.userFullName?.trim().isNotEmpty ?? false)
        ? message.userFullName!.trim()
        : (message.userEmail.isNotEmpty ? message.userEmail : 'Baker');
    final isTypingPlaceholder =
        isAiAssistant && message.isPending && message.content.trim().isEmpty;
    const avatarSlotWidth = 54.0;
    const avatarGap = 10.0;
    const incomingBubbleTopOffset = 6.0;
    const aiAssistantBubbleTopOffset = 18.0;
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
                      ChatAvatar(
                        color: avatarBackgroundColor,
                        icon: avatarIcon,
                        imageAsset: avatarImageAsset,
                        borderColor: isAiAssistant
                            ? _aiChefAvatarBorderColor
                            : null,
                        size: 38,
                      ),
                    ],
                  ),
                ),
              if (!isCurrentUser) const SizedBox(width: avatarGap),
              Padding(
                padding: EdgeInsets.only(
                  top: isCurrentUser
                      ? currentUserBubbleTopOffset
                      : (isAiAssistant
                            ? aiAssistantBubbleTopOffset
                            : incomingBubbleTopOffset),
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
                        if (message.type == ChatMessageType.recipe &&
                            (message.recipeId?.trim().isNotEmpty ?? false))
                          _RecipePreviewCard(
                            recipeId: message.recipeId!,
                            isCurrentUser: isCurrentUser,
                          )
                        else if (message.type == ChatMessageType.recipePreview &&
                            message.metadata != null)
                          AiChefRecipePreview(
                            recipeTitle: message.content,
                            imageUrl: 'assets/default_recipe.jpg',
                            recipePayload: message.metadata!,
                            onViewRecipe: () {
                              final recipe = RecipeModel.fromJson(message.metadata!);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailsPage(
                                    initialRecipe: recipe,
                                    showSaveButton: true,
                                    popRouteAfterSaveAcknowledged: true,
                                  ),
                                ),
                              );
                            },
                          )
                        else if (isTypingPlaceholder)
                          const Padding(
                            padding: EdgeInsets.only(top: 2, bottom: 2),
                            child: AiChefChatTypingDots(),
                          )
                        else
                          Text.rich(
                            _buildCommunityChatTextSpan(
                              message.content,
                              const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Color(0xFF111B26),
                              ),
                            ),
                          ),
                        if (!isTypingPlaceholder) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(message.createdAt),
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
                    child: ChatAvatar(
                      color: avatarBackgroundColor,
                      icon: avatarIcon,
                      imageAsset: avatarImageAsset,
                      borderColor: isAiAssistant
                          ? _aiChefAvatarBorderColor
                          : null,
                      size: 36,
                    ),
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

class _RecipePreviewCard extends ConsumerWidget {
  const _RecipePreviewCard({
    required this.recipeId,
    required this.isCurrentUser,
  });

  final String recipeId;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recipeAsync = ref.watch(sharedRecipeByIdProvider(recipeId));

    return recipeAsync.when(
      loading: () => const SizedBox(
        height: 152,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stackTrace) => _buildUnavailableCard(
        context,
        l10n,
        _recipePreviewMessageForError(l10n, error),
      ),
      data: (recipe) {
        return _buildSharedPreview(context, ref, recipe);
      },
    );
  }

  String _recipePreviewMessageForError(AppLocalizations l10n, Object error) {
    if (error is DioException && error.response?.statusCode == 404) {
      return l10n.recipePreviewNoLongerAvailableMessage;
    }
    return l10n.recipePreviewRefreshHint;
  }

  Widget _buildSharedPreview(
    BuildContext context,
    WidgetRef ref,
    RecipeModel recipe,
  ) {
    Future<void> showSavingDialogAndSave(BuildContext context) async {
      final service = ref.read(recipeServiceProvider);

      var isSaving = true;
      var saveSucceeded = false;
      String? saveErrorMessage;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              if (isSaving) {
                Future.microtask(() async {
                  try {
                    await service.createRecipeCopyWithRemoteImage(recipe);
                    saveSucceeded = true;
                    if (dialogContext.mounted) {
                      setState(() {
                        isSaving = false;
                      });
                    }
                    ref.invalidate(recipesListProvider);
                  } catch (e) {
                    saveSucceeded = false;
                    saveErrorMessage = _userFacingRecipeSaveError(e);
                    if (dialogContext.mounted) {
                      setState(() {
                        isSaving = false;
                      });
                    }
                  }
                });
              }

              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Center(
                  child: SavingStatusCard(
                    isSaving: isSaving,
                    saveSucceeded: saveSucceeded,
                    saveErrorMessage: saveErrorMessage,
                    onOk: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return SharedRecipePreviewCard(
      title: recipe.title,
      imageUrl: recipe.imageUrl,
      healthScore: recipe.healthScore,
      showButtons: !isCurrentUser,
      onView: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailsPage(
              initialRecipe: recipe,
              showSaveButton: true,
              popRouteAfterSaveAcknowledged: true,
            ),
          ),
        );
      },
      onSave: () => showSavingDialogAndSave(context),
    );
  }

  Widget _buildUnavailableCard(
    BuildContext context,
    AppLocalizations l10n,
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: Color(0xFF6D87A0)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.recipePreviewUnavailableTitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF314354),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5B6E83)),
          ),
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
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(isCurrentUser ? 18 : 4),
              topEnd: Radius.circular(isCurrentUser ? 4 : 18),
              bottomStart: const Radius.circular(18),
              bottomEnd: const Radius.circular(18),
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
