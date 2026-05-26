import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class AiChefChatPopupComposer extends StatelessWidget {
  const AiChefChatPopupComposer({
    super.key,
    required this.controller,
    required this.isAwaitingResponse,
    required this.isCheckingInitialConnection,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isAwaitingResponse;
  final bool isCheckingInitialConnection;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFD),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC7D7E4), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF17304A).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: TextField(
                    controller: controller,
                    enabled: !isAwaitingResponse && !isCheckingInitialConnection,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(
                      color: Color(0xFF243447),
                      fontSize: 14.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: l10n.askAiChefHint,
                      hintMaxLines: 1,
                      hintStyle: const TextStyle(
                        color: Color(0xFF7A8EA4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.fromLTRB(8, 11, 8, 11),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 2, right: 10, top: 2),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: const Color(0xFF8BB3D6).withValues(alpha: 0.95),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend =
                      value.text.trim().isNotEmpty &&
                      !isAwaitingResponse &&
                      !isCheckingInitialConnection;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canSend
                          ? const Color(0xFF1F6FC9)
                          : const Color(0xFFD8E1EB),
                    ),
                    child: IconButton(
                      onPressed: canSend ? onSend : null,
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        color: canSend
                            ? Colors.white
                            : const Color(0xFF8D9BAD),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}