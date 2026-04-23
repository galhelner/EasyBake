import 'package:flutter/material.dart';

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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: isConnected,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: isConnecting
                              ? 'Connecting to community chat...'
                              : isConnected
                                  ? 'Share something with the community...'
                                  : 'Chat is offline right now',
                          hintStyle: const TextStyle(
                            color: Color(0xFF7A8EA4),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111B26),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        final canSend = value.text.trim().isNotEmpty && isConnected;
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: isConnected
                    ? 'Share a recipe with the community'
                    : 'Connect to share recipes',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isConnected ? onShareRecipe : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Opacity(
                      opacity: isConnected ? 1 : 0.58,
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFD6E1ED),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              size: 16,
                              color: Color(0xFF8A99AA),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Share recipe',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8A99AA),
                                letterSpacing: 0.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
