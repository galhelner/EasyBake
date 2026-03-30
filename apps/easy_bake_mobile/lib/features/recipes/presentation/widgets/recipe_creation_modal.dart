import 'package:flutter/material.dart';

Future<void> showRecipeCreationModal(
  BuildContext context, {
  required VoidCallback onCreateManually,
  VoidCallback? onCreateFromImage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return RecipeCreationModal(
        onCreateManually: onCreateManually,
        onCreateFromImage: onCreateFromImage,
      );
    },
  );
}

class RecipeCreationModal extends StatelessWidget {
  final VoidCallback onCreateManually;
  final VoidCallback? onCreateFromImage;

  const RecipeCreationModal({
    super.key,
    required this.onCreateManually,
    this.onCreateFromImage,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return AnimatedBuilder(
      animation: const AlwaysStoppedAnimation(1),
      builder: (context, child) => child!,
       child: Padding(
         padding: EdgeInsets.only(
           left: 20,
           right: 20,
           bottom: 24 + safeBottomInset + 12,
         ),
         child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal content
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E4E69).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              color: const Color(0xFF4E677D).withValues(alpha: 0.6),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      'Create Your Recipe',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF20364B),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle
                    Text(
                      'Choose how you\'d like to share your culinary creation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF4E677D).withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Create Manually Button
                    _RecipeCreationButton(
                      icon: Icons.edit_rounded,
                      title: 'Create Recipe Manually',
                      subtitle: 'Add your recipe step by step',
                      onTap: () {
                        Navigator.of(context).pop();
                        onCreateManually();
                      },
                      backgroundColor: const Color(0xFFFFF4E6),
                      iconColor: const Color(0xFFFFC857),
                      titleColor: const Color(0xFF20364B),
                    ),
                    const SizedBox(height: 12),
                    // Create from Image Button
                    _RecipeCreationButton(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Magic: Photo to Recipe',
                      subtitle: 'AI scans your photo and builds the recipe',
                      onTap: onCreateFromImage != null
                          ? () {
                              Navigator.of(context).pop();
                              onCreateFromImage!();
                            }
                          : null,
                      backgroundColor: const Color(0xFFF0F4F7),
                      iconColor: const Color(0xFF8BB3D6),
                      titleColor: const Color(0xFF20364B),
                      isDisabled: onCreateFromImage == null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCreationButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final bool isDisabled;

  const _RecipeCreationButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDisabled
                            ? titleColor.withValues(alpha: 0.5)
                            : titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF4E677D).withValues(
                          alpha: isDisabled ? 0.4 : 0.6,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: iconColor.withValues(alpha: isDisabled ? 0.3 : 0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
