import 'package:flutter/material.dart';

class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.isConnecting,
    required this.onSend,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isInputEmpty = controller.text.trim().isEmpty;
    final canSend = !isInputEmpty && isConnected;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                enabled: isConnected,
                maxLines: null,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111B26),
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canSend ? const Color(0xFF1565C0) : Colors.grey.shade300,
              boxShadow: canSend
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: IconButton(
              onPressed: canSend ? onSend : null,
              icon: Icon(
                Icons.send_rounded,
                color: canSend ? Colors.white : Colors.grey.shade500,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
