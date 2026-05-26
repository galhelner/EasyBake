import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.isConnecting,
    required this.onSend,
    required this.onShareRecipe,
  });

  final TextEditingController controller;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onSend;
  final VoidCallback onShareRecipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB).withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(
              color: const Color(0xFFCCD9E8).withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD4E0EE), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF113257).withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (context, value, _) {
                          final hasText = value.text.trim().isNotEmpty;
                          final maxLines = hasText ? 4 : 5;

                          return TextField(
                            controller: controller,
                            enabled: isConnected,
                            keyboardType: TextInputType.multiline,
                            maxLines: maxLines,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              prefixIconConstraints: BoxConstraints(
                                minWidth: hasText ? 36 : 40,
                                minHeight: hasText ? 36 : 40,
                              ),
                              prefixIcon: Center(
                                widthFactor: 1,
                                heightFactor: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    right: 6,
                                  ),
                                  child: Semantics(
                                    label: isConnected
                                      ? l10n.shareRecipeWithCommunityLabel
                                      : l10n.connectToShareRecipesLabel,
                                    button: true,
                                    enabled: isConnected,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: isConnected
                                            ? onShareRecipe
                                            : null,
                                        customBorder: const CircleBorder(),
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: isConnected
                                                ? const Color(0xFFE7F1FF)
                                                : const Color(0xFFF3F6FA),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isConnected
                                                  ? const Color(0xFFB9D5FF)
                                                  : const Color(0xFFD6E1ED),
                                              width: 1,
                                            ),
                                            boxShadow: isConnected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF1F6FC9,
                                                      ).withValues(alpha: 0.12),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ]
                                                : const [],
                                          ),
                                          child: Icon(
                                            Icons.attach_file_rounded,
                                            size: 16,
                                            color: isConnected
                                                ? const Color(0xFF1F6FC9)
                                                : const Color(0xFF8D9BAD),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              hintText: isConnecting
                                  ? l10n.composerConnectingHint
                                  : isConnected
                                  ? l10n.composerShareHint
                                  : l10n.composerOfflineHint,
                              hintStyle: const TextStyle(
                                color: Color(0xFF7A8EA4),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: hasText ? 8 : 12,
                              ),
                              isDense: true,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF111B26),
                              height: 1.35,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        final canSend =
                            value.text.trim().isNotEmpty && isConnected;
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
                          child: Center(
                            child: IconButton(
                              // Disable Material tooltip: this button lives inside a
                              // ValueListenableBuilder that rebuilds on every keystroke.
                              // Default IconButton tooltips use RawTooltip + a single ticker;
                              // rapid rebuilds can throw "multiple tickers were created".
                              tooltip: '',
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
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
