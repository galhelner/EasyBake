import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiChefChatPopupHeader extends StatelessWidget {
  const AiChefChatPopupHeader({
    super.key,
    required this.isCheckingInitialConnection,
    required this.isServiceOnline,
    required this.isRefreshingConnection,
    required this.onRefreshConnection,
    required this.onClose,
    this.onClearChat,
  });

  final bool isCheckingInitialConnection;
  final bool isServiceOnline;
  final bool isRefreshingConnection;
  final VoidCallback onRefreshConnection;
  final VoidCallback onClose;
  final VoidCallback? onClearChat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEAF2F5), Color(0xFFDCE8EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFFD0DCE3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFF3C536B),
                size: 20,
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: EdgeInsets.zero,
              splashRadius: 16,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFDFCF8), Color(0xFFFFF0D9)],
                  ),
                  border: Border.all(
                    color: const Color(0xFF2E4E69).withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E4E69).withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.85),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/ai_chef_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.aiChefPopupTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF253852),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiChefPopupSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF557089),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCheckingInitialConnection
                      ? const Color(0xFFE3F2FD)
                      : isServiceOnline
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCheckingInitialConnection
                        ? const Color(0xFFD3DADF)
                        : isServiceOnline
                            ? const Color(0xFFA5D6A7)
                            : const Color(0xFFF48FB1),
                  ),
                ),
                child: Text(
                  isCheckingInitialConnection
                      ? l10n.aiChefPopupCheckingLabel
                      : isServiceOnline
                          ? l10n.connectionPillOnlineLabel
                          : l10n.connectionPillOfflineLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isCheckingInitialConnection
                        ? const Color(0xFF6A7884)
                        : isServiceOnline
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC2185B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isServiceOnline && !isCheckingInitialConnection) ...[
                const SizedBox(width: 4),
                SizedBox(
                  height: 28,
                  child: OutlinedButton.icon(
                    onPressed: isRefreshingConnection ? null : onRefreshConnection,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDAA4A4)),
                      foregroundColor: const Color(0xFFB93838),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    icon: isRefreshingConnection
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: Color(0xFFB93838),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 14),
                    label: Text(
                      l10n.aiChefPopupRefreshLabel,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                onPressed: onClearChat,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: onClearChat != null ? Colors.red[400] : null,
                ),
                tooltip: l10n.clearButtonLabel,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
