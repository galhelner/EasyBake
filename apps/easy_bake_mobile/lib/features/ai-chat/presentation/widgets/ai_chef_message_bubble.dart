import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'chat_message_builder.dart';

class AiChefMessageBubble extends StatelessWidget {
  const AiChefMessageBubble({
    super.key,
    required this.message,
    required this.maxWidth,
    required this.onOpenRecipe,
    required this.onRecipeTap,
    required this.onNavigateToShoppingList,
    required this.onCopy,
  });

  final ChatMessage message;
  final double maxWidth;
  final VoidCallback onOpenRecipe;
  final Function(Map<String, dynamic>) onRecipeTap;
  final VoidCallback onNavigateToShoppingList;
  final VoidCallback onCopy;

  bool get _canCopy =>
      message.kind != ChatMessageKind.typing &&
      message.kind != ChatMessageKind.connectionChecking;

  Future<void> _showCopyMenu(BuildContext context, Offset globalPosition) async {
    final l10n = AppLocalizations.of(context)!;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    HapticFeedback.mediumImpact();

    final selected = await showMenu<String>(
      context: context,
      color: Colors.white,
      elevation: 10.0,
      shadowColor: const Color(0xFF17324B).withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: Color(0xFFDDEBFF), width: 1.0),
      ),
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          height: 46.0,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _CopyPopupActionRow(label: l10n.copyTextLabel),
        ),
      ],
    );

    if (selected == 'copy') {
      onCopy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAi = message.sender == ChatSender.ai;

    final bubbleRadius = BorderRadiusDirectional.only(
      topStart: Radius.circular(isAi ? 4.0 : 16.0),
      topEnd: Radius.circular(isAi ? 16.0 : 4.0),
      bottomStart: const Radius.circular(16.0),
      bottomEnd: const Radius.circular(16.0),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: isAi
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              isAi ? const _MessagePierreAvatar() : const _MessageUserAvatar(),
              const SizedBox(height: 4.0),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: isAi ? 24.0 : 0.0,
                  end: isAi ? 0.0 : 24.0,
                ),
                child: GestureDetector(
                  onLongPressStart: _canCopy
                      ? (details) =>
                          _showCopyMenu(context, details.globalPosition)
                      : null,
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      14.0,
                      10.0,
                      14.0,
                      10.0,
                    ),
                    decoration: isAi
                        ? BoxDecoration(
                            color: Colors.white,
                            borderRadius: bubbleRadius,
                            border: Border.all(
                              color: const Color(0xFFDDEBFF),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF17324B)
                                    .withValues(alpha: 0.06),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          )
                        : BoxDecoration(
                            gradient: const LinearGradient(
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                              colors: [Color(0xFF315C84), Color(0xFF2E4E69)],
                            ),
                            borderRadius: bubbleRadius,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF17324B)
                                    .withValues(alpha: 0.14),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                    child: ChatMessageBuilder(
                      message: message,
                      textColor: isAi ? const Color(0xFF17324B) : Colors.white,
                      onOpenRecipe: onOpenRecipe,
                      onRecipeTap: onRecipeTap,
                      onNavigateToShoppingList: onNavigateToShoppingList,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyPopupActionRow extends StatelessWidget {
  const _CopyPopupActionRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30.0,
          height: 30.0,
          decoration: const BoxDecoration(
            color: Color(0xFFDDEBFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.copy_rounded,
            size: 16.0,
            color: Color(0xFF17324B),
          ),
        ),
        const SizedBox(width: 10.0),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF17324B),
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MessagePierreAvatar extends StatelessWidget {
  const _MessagePierreAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.0,
      height: 36.0,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFFF6FAFF), Color(0xFFDDEBFF)],
        ),
        border: Border.all(
          color: const Color(0xFF8BB3D6).withValues(alpha: 0.55),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17324B).withValues(alpha: 0.08),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/pierre_portrait.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _MessageUserAvatar extends StatelessWidget {
  const _MessageUserAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.0,
      height: 36.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF315C84), Color(0xFF17324B)],
        ),
        border: Border.all(
          color: const Color(0xFF8BB3D6).withValues(alpha: 0.45),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17324B).withValues(alpha: 0.12),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 19.0,
        color: Colors.white,
      ),
    );
  }
}
