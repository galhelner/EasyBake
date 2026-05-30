import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class HomeBottomTabBar extends StatefulWidget {
  const HomeBottomTabBar({
    required this.currentIndex,
    required this.onTabSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  State<HomeBottomTabBar> createState() => _HomeBottomTabBarState();
}

class _HomeBottomTabBarState extends State<HomeBottomTabBar> {
  late List<int> _hoveredIndices;

  @override
  void initState() {
    super.initState();
    _hoveredIndices = List<int>.filled(5, 0);
  }

  String _labelForIndex(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return l10n.profileLabel;
      case 1:
        return l10n.communityChatLabel;
      case 2:
        return l10n.homeLabel;
      case 3:
        return l10n.recipesLabel;
      case 4:
        return l10n.shoppingListLabel;
      default:
        return l10n.homeLabel;
    }
  }

  String _tooltipForIndex(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return l10n.profileTooltip;
      case 1:
        return l10n.communityChatTooltip;
      case 2:
        return l10n.homeTooltip;
      case 3:
        return l10n.recipesLabel;
      case 4:
        return l10n.shoppingListLabel;
      default:
        return l10n.homeTooltip;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 68.0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: barHeight + bottomInset + 12,
        child: ColoredBox(
          color: const Color(0xFFF0F5FA),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset + 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFFF8FBFE),
                border: Border.all(color: const Color(0xFFD7E4EF), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF17324B).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double edgeInset = 8.0;
                  const double indicatorWidth = 68.0;
                  const double indicatorHeight = 48.0;
                  final double indicatorTop =
                      (constraints.maxHeight - indicatorHeight) / 2;
                  final double innerWidth = constraints.maxWidth - (edgeInset * 2);
                  final double segmentWidth = innerWidth / 5;
                  final double indicatorStart =
                      (segmentWidth * widget.currentIndex) +
                      ((segmentWidth - indicatorWidth) / 2);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: edgeInset),
                    child: Stack(
                      children: [
                        AnimatedPositionedDirectional(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          start: indicatorStart,
                          top: indicatorTop,
                          width: indicatorWidth,
                          height: indicatorHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(color: const Color(0xFFD9EAF8)),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _TabIconButton(
                                tooltip: _tooltipForIndex(context, 0),
                                label: _labelForIndex(context, 0),
                                selected: widget.currentIndex == 0,
                                icon: Icons.person_rounded,
                                onTap: () => widget.onTabSelected(0),
                                isHovered: _hoveredIndices[0] > 0,
                                onHoverChange: (hovering) {
                                  setState(() {
                                    _hoveredIndices[0] = hovering ? 1 : 0;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _TabIconButton(
                                tooltip: _tooltipForIndex(context, 1),
                                label: _labelForIndex(context, 1),
                                selected: widget.currentIndex == 1,
                                icon: Icons.forum_rounded,
                                onTap: () => widget.onTabSelected(1),
                                isHovered: _hoveredIndices[1] > 0,
                                onHoverChange: (hovering) {
                                  setState(() {
                                    _hoveredIndices[1] = hovering ? 1 : 0;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _TabIconButton(
                                tooltip: _tooltipForIndex(context, 2),
                                label: _labelForIndex(context, 2),
                                selected: widget.currentIndex == 2,
                                icon: Icons.home_rounded,
                                onTap: () => widget.onTabSelected(2),
                                isHovered: _hoveredIndices[2] > 0,
                                onHoverChange: (hovering) {
                                  setState(() {
                                    _hoveredIndices[2] = hovering ? 1 : 0;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _TabIconButton(
                                tooltip: _tooltipForIndex(context, 3),
                                label: _labelForIndex(context, 3),
                                selected: widget.currentIndex == 3,
                                icon: Icons.restaurant_menu_rounded,
                                onTap: () => widget.onTabSelected(3),
                                isHovered: _hoveredIndices[3] > 0,
                                onHoverChange: (hovering) {
                                  setState(() {
                                    _hoveredIndices[3] = hovering ? 1 : 0;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _TabIconButton(
                                tooltip: _tooltipForIndex(context, 4),
                                label: _labelForIndex(context, 4),
                                selected: widget.currentIndex == 4,
                                icon: Icons.list_alt_rounded,
                                onTap: () => widget.onTabSelected(4),
                                isHovered: _hoveredIndices[4] > 0,
                                onHoverChange: (hovering) {
                                  setState(() {
                                    _hoveredIndices[4] = hovering ? 1 : 0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIconButton extends StatefulWidget {
  const _TabIconButton({
    required this.tooltip,
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
    required this.isHovered,
    required this.onHoverChange,
  });

  final String tooltip;
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final bool isHovered;
  final ValueChanged<bool> onHoverChange;

  @override
  State<_TabIconButton> createState() => _TabIconButtonState();
}

class _TabIconButtonState extends State<_TabIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    _tapController.forward();
  }

  void _handleTapUp(_) {
    _tapController.reverse();
  }

  void _handleTapCancel() {
    _tapController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.tooltip,
      enabled: true,
      onTap: widget.onTap,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => widget.onHoverChange(true),
          onExit: (_) => widget.onHoverChange(false),
          child: Center(
            child: AnimatedBuilder(
              animation: _tapController,
              builder: (context, child) {
                final tapScale = 1.0 - (_tapController.value * 0.08);
                return Transform.scale(scale: tapScale, child: child);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      widget.icon,
                      size: widget.selected ? 24 : 22,
                      color: widget.selected
                          ? const Color(0xFF17324B)
                          : const Color(0xFF7A95B1),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 9.2,
                      fontWeight:
                          widget.selected ? FontWeight.w800 : FontWeight.w600,
                      color: widget.selected
                          ? const Color(0xFF17324B)
                          : const Color(0xFF7A95B1),
                      letterSpacing: 0.2,
                    ),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

