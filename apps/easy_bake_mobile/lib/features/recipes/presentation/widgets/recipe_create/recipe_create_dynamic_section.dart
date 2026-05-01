import 'package:flutter/material.dart';



class RecipeCreateDynamicSection extends StatefulWidget {
  final String title;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final Color primaryColor;
  final String? errorText;

  const RecipeCreateDynamicSection({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    required this.onAdd,
    required this.onRemove,
    required this.primaryColor,
    this.errorText,
  });

  @override
  State<RecipeCreateDynamicSection> createState() => _RecipeCreateDynamicSectionState();
}

class _RecipeCreateDynamicSectionState extends State<RecipeCreateDynamicSection> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final isEditingActive = _isEditing && widget.itemCount > 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: _FieldActionButton(
                  onTap: widget.itemCount > 1
                      ? () {
                          setState(() {
                            _isEditing = !_isEditing;
                          });
                        }
                      : () {},
                  icon: isEditingActive ? Icons.check_rounded : Icons.edit_rounded,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: _FieldActionButton(
                  onTap: widget.onAdd,
                  icon: Icons.add_rounded,
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < widget.itemCount; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: widget.itemBuilder(context, i),
              ),
              if (isEditingActive) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: _FieldActionButton(
                    onTap: () => widget.onRemove(i),
                    icon: Icons.remove_rounded,
                    isRemove: true,
                  ),
                ),
              ],
            ],
          ),
          if (i < widget.itemCount - 1) const SizedBox(height: 10),
        ],
        if (widget.errorText != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    ),
    );
  }
}

class _FieldActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool isRemove;

  const _FieldActionButton({
    required this.onTap,
    required this.icon,
    this.isRemove = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 48,
          decoration: BoxDecoration(
            color: isRemove
                ? const Color(0xFFFF3B30).withValues(alpha: 0.08)
                : const Color(0xFF8BB3D6).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isRemove
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.2)
                  : const Color(0xFF8BB3D6).withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isRemove
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFF8BB3D6),
            ),
          ),
        ),
      ),
    );
  }
}
