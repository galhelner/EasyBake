import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class AiChefChatButton extends StatefulWidget {
  const AiChefChatButton({
    super.key,
    this.onTap,
    this.logoAssetPath = 'assets/pierre_portrait.png',
    this.label,
  });

  final VoidCallback? onTap;
  final String logoAssetPath;
  final String? label;

  @override
  State<AiChefChatButton> createState() => _AiChefChatButtonState();
}

class _AiChefChatButtonState extends State<AiChefChatButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;
  late final Animation<double> _sparkleScale;
  late final Animation<double> _sparkleOpacity;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    final curved = CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    );
    _sparkleScale = Tween<double>(begin: 0.9, end: 1.12).animate(curved);
    _sparkleOpacity = Tween<double>(begin: 0.72, end: 1.0).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (disableAnimations || !tickerEnabled) {
      if (_sparkleController.isAnimating) {
        _sparkleController.stop();
      }
      _sparkleController.value = 1.0;
    } else if (!_sparkleController.isAnimating) {
      _sparkleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedLabel = widget.label ?? l10n.askPierreLabel;

    return Semantics(
      button: true,
      label: l10n.askAiChefHint,
      enabled: widget.onTap != null,
      child: Tooltip(
        message: l10n.askAiChefHint,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
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
                  color: const Color(0xFF17324B).withValues(alpha: 0.24),
                  blurRadius: 16.0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF8BB3D6).withValues(alpha: 0.16),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16.0),
                splashColor: Colors.white.withValues(alpha: 0.16),
                highlightColor: Colors.white.withValues(alpha: 0.08),
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                onTap: widget.onTap,
                child: SizedBox(
                  height: 56.0,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      8.0,
                      8.0,
                      16.0,
                      8.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AiChefAvatarBadge(
                          logoAssetPath: widget.logoAssetPath,
                        ),
                        const SizedBox(width: 8.0),
                        _AiChefButtonLabels(
                          title: resolvedLabel,
                          subtitle: l10n.aiChefName,
                          sparkleScale: _sparkleScale,
                          sparkleOpacity: _sparkleOpacity,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiChefAvatarBadge extends StatelessWidget {
  const _AiChefAvatarBadge({required this.logoAssetPath});

  final String logoAssetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFFF6FAFF), Color(0xFFDDEBFF)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.78),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3559).withValues(alpha: 0.22),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          logoAssetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _AiChefButtonLabels extends StatelessWidget {
  const _AiChefButtonLabels({
    required this.title,
    required this.subtitle,
    required this.sparkleScale,
    required this.sparkleOpacity,
  });

  final String title;
  final String subtitle;
  final Animation<double> sparkleScale;
  final Animation<double> sparkleOpacity;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 2.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: sparkleOpacity,
              child: ScaleTransition(
                scale: sparkleScale,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 11.0,
                  color: Color(0xFFDDEBFF),
                ),
              ),
            ),
            const SizedBox(width: 4.0),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFDDEBFF),
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
