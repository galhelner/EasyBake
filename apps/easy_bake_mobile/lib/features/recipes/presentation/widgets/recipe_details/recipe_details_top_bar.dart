import 'package:flutter/material.dart';

import 'recipe_details_theme.dart';

class RecipeDetailsTopBar extends StatelessWidget {
  const RecipeDetailsTopBar({
    super.key,
    required this.onBack,
    required this.onMenuSelected,
    required this.isMenuDisabled,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onMenuSelected;
  final bool isMenuDisabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onBack,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: kRecipeDetailsPrimaryBlue,
                ),
                SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: kRecipeDetailsPrimaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        PopupMenuButton<String>(
          enabled: !isMenuDisabled,
          onSelected: isMenuDisabled ? null : onMenuSelected,
          color: Colors.white,
          elevation: 14,
          shadowColor: const Color(0x29304466),
          surfaceTintColor: Colors.white,
          constraints: const BoxConstraints(minWidth: 236),
          menuPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE4EAF2)),
          ),
          offset: const Offset(0, 10),
          tooltip: 'Recipe actions',
          icon: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF3F7FC)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD5DFEC)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A304466),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.more_horiz,
              size: 22,
              color: isMenuDisabled
                  ? const Color(0xFF9BA8B7)
                  : kRecipeDetailsPrimaryBlue,
            ),
          ),
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              height: 68,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              value: 'edit',
              child: _RecipeMenuItem(
                icon: Icons.edit_outlined,
                label: 'Edit',
                subtitle: 'Update title, image, or steps',
                iconColor: kRecipeDetailsPrimaryBlue,
                textColor: Color(0xFF1B2A41),
                backgroundColor: Color(0xFFF5F9FF),
                borderColor: Color(0xFFDAE6F5),
              ),
            ),
            PopupMenuItem<String>(
              height: 68,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              value: 'delete',
              child: _RecipeMenuItem(
                icon: Icons.delete_outline,
                label: 'Delete',
                subtitle: 'Remove this recipe permanently',
                iconColor: Color(0xFFD14343),
                textColor: Color(0xFFB83232),
                backgroundColor: Color(0xFFFFF4F4),
                borderColor: Color(0xFFF4D1D1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecipeMenuItem extends StatelessWidget {
  const _RecipeMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6D7E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: textColor.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}
