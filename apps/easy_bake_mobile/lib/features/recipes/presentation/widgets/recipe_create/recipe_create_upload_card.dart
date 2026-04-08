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

    return Center(
      child: GestureDetector(
        onTap: hasImage ? onReplace : onReplace,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320, maxHeight: 180),
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
            child: !hasImage
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 32,
                          color: primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Recipe Image',
                      style: TextStyle(
                        color: const Color(0xFF2E4E69),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PNG, JPG up to 5MB',
                      style: TextStyle(
                        color: const Color(0xFF4E677D).withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                )
              : Stack(
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
