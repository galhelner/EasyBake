import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../domain/models/recipe_model.dart';
import '../../../../profile/presentation/providers/user_preferences_notifier.dart';
import '../../pages/recipe_details_page.dart';
import 'recipe_card_delete_overlay.dart';

enum RecipeCardVariant { list, dashboard }

class RecipeCard extends StatefulWidget {
  final RecipeModel recipe;
  final String? imageUrl;
  final Color statusColor;
  final RecipeCardVariant variant;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.imageUrl,
    required this.statusColor,
    this.variant = RecipeCardVariant.list,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _showingDeleteOverlay = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _showDeleteOverlay() {
    setState(() => _showingDeleteOverlay = true);
  }

  void _hideDeleteOverlay() {
    setState(() => _showingDeleteOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDashboardVariant = widget.variant == RecipeCardVariant.dashboard;
    final outerBorderRadius = BorderRadius.circular(
      isDashboardVariant ? 18 : 16,
    );
    final contentBorderRadius = BorderRadius.circular(
      isDashboardVariant ? 18 : 16,
    );
    final surfaceColor = isDashboardVariant
        ? const Color(0xFFF6FAFE)
        : Colors.white;
    final borderColor = isDashboardVariant
        ? const Color(0xFFDCE7F1)
        : Colors.transparent;
    final shadowColor = isDashboardVariant
        ? const Color(0xFF2E4E69).withValues(alpha: 0.06)
        : const Color(0xFF2E4E69).withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -8 * _hoverAnimation.value),
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => _hoverController.forward(),
        onExit: (_) => _hoverController.reverse(),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeDetailsPage(initialRecipe: widget.recipe),
              ),
            );
          },
          onLongPress: _showDeleteOverlay,
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: outerBorderRadius,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: isDashboardVariant ? 12 : 16,
                  offset: Offset(0, isDashboardVariant ? 3 : 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: contentBorderRadius,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(
                                isDashboardVariant ? 18 : 16,
                              ),
                              topRight: Radius.circular(
                                isDashboardVariant ? 18 : 16,
                              ),
                            ),
                            child: SizedBox(
                              height: 100,
                              width: double.infinity,
                              child:
                                  (widget.imageUrl != null &&
                                      widget.imageUrl!.isNotEmpty)
                                  ? Image.network(
                                      widget.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFFF0F4F7),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: const Color(
                                              0xFF8BB3D6,
                                            ).withValues(alpha: 0.4),
                                            size: 32,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: const Color(0xFFF0F4F7),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: const Color(
                                          0xFF8BB3D6,
                                        ).withValues(alpha: 0.4),
                                        size: 32,
                                      ),
                                    ),
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final show = ref.watch(
                                healthyModeEnabledProvider,
                              );
                              if (!show) return const SizedBox.shrink();
                              return Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.statusColor.withValues(
                                      alpha: 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.statusColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getHealthIcon(
                                          widget.recipe.healthScore,
                                        ),
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getHealthLabel(
                                          l10n,
                                          widget.recipe.healthScore,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isDashboardVariant ? 14 : 12,
                            10,
                            isDashboardVariant ? 14 : 12,
                            isDashboardVariant ? 12 : 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: isDashboardVariant ? 38 : 34,
                                child: Text(
                                  widget.recipe.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                  textHeightBehavior: const TextHeightBehavior(
                                    applyHeightToFirstAscent: false,
                                    applyHeightToLastDescent: false,
                                  ),
                                  strutStyle: StrutStyle(
                                    fontSize: isDashboardVariant ? 14.5 : 14,
                                    height: 1,
                                    forceStrutHeight: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: isDashboardVariant ? 14.5 : 14,
                                    fontWeight: isDashboardVariant
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: const Color(0xFF20364B),
                                    height: 1,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_rounded,
                                    size: 14,
                                    color: isDashboardVariant
                                        ? const Color(0xFF587185)
                                        : const Color(0xFF2E4E69),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      l10n.shareRecipeIngredientsCount(
                                        widget.recipe.ingredients.length,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDashboardVariant
                                            ? const Color(0xFF5B6F81)
                                            : const Color(0xFF4E677D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showingDeleteOverlay)
                  RecipeCardDeleteOverlay(
                    recipe: widget.recipe,
                    onClose: _hideDeleteOverlay,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getHealthLabel(AppLocalizations l10n, int healthScore) {
    if (healthScore >= 70) {
      return l10n.healthyBadgeLabel;
    } else if (healthScore >= 40) {
      return l10n.averageBadgeLabel;
    } else {
      return l10n.unhealthyBadgeLabel;
    }
  }

  IconData _getHealthIcon(int healthScore) {
    if (healthScore >= 70) {
      return Icons.favorite;
    } else {
      return Icons.warning_rounded;
    }
  }
}
