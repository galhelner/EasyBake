import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class EmptyState extends StatelessWidget {
  final bool isOffline;

  const EmptyState({super.key, this.isOffline = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = isOffline
        ? l10n.communityChatOfflineTitle
        : l10n.communityChatEmptyTitle;
    final subtitle = isOffline
        ? l10n.communityChatOfflineSubtitle
        : l10n.communityChatEmptySubtitle;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isOffline ? Icons.cloud_off_outlined : Icons.forum_outlined,
              size: 40,
              color: const Color(0xFF99A3AF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111B26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
