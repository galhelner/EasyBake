import 'package:flutter/material.dart';
import 'dart:typed_data';

class RecipeCreateUploadCard extends StatelessWidget {
  final Color primaryColor;
  final Color backgroundColor;
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const RecipeCreateUploadCard({
    super.key,
    required this.primaryColor,
    required this.backgroundColor,
    required this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
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
          child: imageBytes == null
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
                      child: Image.memory(imageBytes!, fit: BoxFit.cover),
                    ),
                    // Overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                    // Change photo button
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Color(0xFF8BB3D6),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Change photo',
                              style: TextStyle(
                                color: Color(0xFF8BB3D6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
