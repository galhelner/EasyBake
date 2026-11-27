import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 10.0, 12.0, 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0)),
        border: Border(
          top: BorderSide(color: Color(0xFFDDEBFF), width: 1.0),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(color: const Color(0xFFDDEBFF), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12.0, 6.0, 6.0, 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 132.0),
                  child: TextField(
                    controller: controller,
                    enabled: !isAwaitingResponse && !isCheckingInitialConnection,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(
                      color: Color(0xFF17324B),
                      fontSize: 14.0,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: l10n.askAiChefHint,
                      hintMaxLines: 1,
                      hintStyle: const TextStyle(
                        color: Color(0xFF7A8EA4),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsetsDirectional.fromSTEB(
                        4.0,
                        10.0,
                        8.0,
                        10.0,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 2.0,
                          end: 8.0,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18.0,
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
              const SizedBox(width: 8.0),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend =
                      value.text.trim().isNotEmpty &&
                      !isAwaitingResponse &&
                      !isCheckingInitialConnection;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: canSend
                          ? const LinearGradient(
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                              colors: [Color(0xFF315C84), Color(0xFF17324B)],
                            )
                          : null,
                      color: canSend ? null : const Color(0xFFDDEBFF),
                    ),
                    child: IconButton(
                      onPressed: canSend ? onSend : null,
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        color: canSend
                            ? Colors.white
                            : const Color(0xFF8BB3D6),
                        size: 20.0,
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
