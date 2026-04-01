import 'package:flutter/material.dart';

class HomeBottomTabBar extends StatelessWidget {
  const HomeBottomTabBar({
    required this.currentIndex,
    required this.onTabSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  IconData _iconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.forum_rounded;
      case 2:
        return Icons.person_rounded;
      case 1:
      default:
        return Icons.home_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 58.0;
    const pillHeight = 46.0;

    return SizedBox(
      height: barHeight + bottomInset + 12,
      child: ColoredBox(
        color: const Color(0xFFEDF1F6),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, bottomInset + 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF95BDDC), Color(0xFF7EACD0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2B1E3850),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPadding = 5.0;
                final segmentWidth =
                    (constraints.maxWidth - (horizontalPadding * 2)) / 3;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: horizontalPadding + (segmentWidth * currentIndex),
                      top: (barHeight - pillHeight) / 2,
                      width: segmentWidth,
                      height: pillHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFF2E4E69),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3D122738),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconForIndex(currentIndex),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _TabIconButton(
                            tooltip: 'Community Chat Room',
                            selected: currentIndex == 0,
                            icon: Icons.forum_rounded,
                            onTap: () => onTabSelected(0),
                          ),
                        ),
                        Expanded(
                          child: _TabIconButton(
                            tooltip: 'Home',
                            selected: currentIndex == 1,
                            icon: Icons.home_rounded,
                            onTap: () => onTabSelected(1),
                          ),
                        ),
                        Expanded(
                          child: _TabIconButton(
                            tooltip: 'Profile',
                            selected: currentIndex == 2,
                            icon: Icons.person_rounded,
                            onTap: () => onTabSelected(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIconButton extends StatelessWidget {
  const _TabIconButton({
    required this.tooltip,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        splashRadius: 22,
        icon: Icon(
          icon,
          size: 22,
          color: selected
              ? Colors.transparent
              : const Color(0xFFEEF6FC).withValues(alpha: 0.94),
        ),
      ),
    );
  }
}
