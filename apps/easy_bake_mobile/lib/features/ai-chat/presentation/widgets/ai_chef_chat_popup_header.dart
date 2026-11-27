import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

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
    final statusColor = isCheckingInitialConnection
        ? const Color(0xFF8BB3D6)
        : isServiceOnline
        ? const Color(0xFF4ADE80)
        : const Color(0xFFF87171);

    final showOfflineBanner = !isServiceOnline && !isCheckingInitialConnection;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF315C84), Color(0xFF17324B)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              16.0,
              14.0,
              12.0,
              14.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HeaderPierreAvatar(statusColor: statusColor),
                const SizedBox(width: 12.0),
                Expanded(
                  child: _HeaderTitleBlock(
                    title: l10n.aiChefPopupSubtitle,
                    roleLabel: l10n.aiChefHeaderRoleLabel,
                  ),
                ),
                const SizedBox(width: 8.0),
                if (onClearChat != null) ...[
                  _HeaderActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: l10n.clearButtonLabel,
                    onPressed: onClearChat,
                  ),
                  const SizedBox(width: 6.0),
                ],
                _HeaderActionButton(
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          if (showOfflineBanner)
            _OfflineReconnectBanner(
              label: l10n.connectionPillOfflineLabel,
              refreshLabel: l10n.aiChefPopupRefreshLabel,
              isRefreshing: isRefreshingConnection,
              onRefresh: onRefreshConnection,
            ),
        ],
      ),
    );
  }
}

class _HeaderPierreAvatar extends StatelessWidget {
  const _HeaderPierreAvatar({required this.statusColor});

  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52.0,
      height: 52.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52.0,
            height: 52.0,
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [Color(0xFFF6FAFF), Color(0xFFDDEBFF)],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F3559).withValues(alpha: 0.28),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/pierre_portrait.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: Container(
              width: 14.0,
              height: 14.0,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF17324B), width: 2.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTitleBlock extends StatelessWidget {
  const _HeaderTitleBlock({required this.title, required this.roleLabel});

  final String title;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17.0,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.1,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 12.0,
              color: Color(0xFFDDEBFF),
            ),
            const SizedBox(width: 4.0),
            Flexible(
              child: Text(
                roleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Color(0xFFDDEBFF),
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 34.0,
            height: 34.0,
            child: Icon(icon, size: 18.0, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _OfflineReconnectBanner extends StatelessWidget {
  const _OfflineReconnectBanner({
    required this.label,
    required this.refreshLabel,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final String label;
  final String refreshLabel;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 12.0, 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 15.0,
            color: Color(0xFFFCA5A5),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFEE2E2),
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          SizedBox(
            height: 28.0,
            child: TextButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              icon: isRefreshing
                  ? const SizedBox(
                      width: 12.0,
                      height: 12.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 14.0),
              label: Text(
                refreshLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
