import 'package:flutter/material.dart';
import 'dart:typed_data';

class RecipeCreateUploadCard extends StatelessWidget {
  final Color primaryColor;
  final Color backgroundColor;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback onReplace;
  final VoidCallback? onDelete;

  const RecipeCreateUploadCard({
    super.key,
    required this.primaryColor,
    required this.backgroundColor,
    required this.imageBytes,
    this.imageUrl,
    required this.onReplace,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImageBytes = imageBytes != null;
    final hasImageUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasImage = hasImageBytes || hasImageUrl;

    if (!hasImage) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onReplace,
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryColor.withValues(alpha: 0.08),
          highlightColor: primaryColor.withValues(alpha: 0.04),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 92),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [backgroundColor, primaryColor.withValues(alpha: 0.07)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 22,
                          color: primaryColor.withValues(alpha: 0.88),
                        ),
                        Positioned(
                          right: 7,
                          bottom: 7,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 9,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Recipe Image',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gallery or camera',
                          style: TextStyle(
                            color: primaryColor.withValues(alpha: 0.7),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: primaryColor.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: GestureDetector(
        onTap: onReplace,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 260),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImageBytes
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFDFE7ED),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: primaryColor.withValues(alpha: 0.65),
                            size: 34,
                          ),
                        ),
                      ),
              ),
              // Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ImageActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Replace',
                        onTap: onReplace,
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 8),
                        _ImageActionButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          onTap: onDelete!,
                          accentColor: const Color(0xFFD85B5B),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  const _ImageActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColor = const Color(0xFF8BB3D6),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
