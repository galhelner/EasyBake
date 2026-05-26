import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class RecipeCreateDynamicSection extends StatefulWidget {
  final String title;
  final int itemCount;
  final int minItemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final Color primaryColor;
  final String? errorText;

  const RecipeCreateDynamicSection({
    super.key,
    required this.title,
    required this.itemCount,
    this.minItemCount = 1,
    required this.itemBuilder,
    required this.onAdd,
    required this.onRemove,
    required this.primaryColor,
    this.errorText,
  });

  @override
  State<RecipeCreateDynamicSection> createState() =>
      _RecipeCreateDynamicSectionState();
}

class _RecipeCreateDynamicSectionState
    extends State<RecipeCreateDynamicSection> {
  bool _isEditing = false;

  @override
  void didUpdateWidget(RecipeCreateDynamicSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset edit mode if item count changes to <= 1 (edit button won't show)
    if (widget.itemCount <= widget.minItemCount && _isEditing) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditingActive = _isEditing && widget.itemCount > widget.minItemCount;
    final isIngredientsSection = widget.title == l10n.ingredientsTabLabel;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      isIngredientsSection
                          ? Icons.shopping_bag_outlined
                          : Icons.list_alt_outlined,
                      size: 22,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.recipeItemsCount(widget.itemCount),
                        style: TextStyle(
                          color: widget.primaryColor.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (widget.itemCount > widget.minItemCount)
                  _CompactActionButton(
                    onTap: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    icon: isEditingActive
                        ? Icons.check_rounded
                        : Icons.edit_rounded,
                    primaryColor: widget.primaryColor,
                  ),
                const SizedBox(width: 6),
                _CompactActionButton(
                  onTap: widget.onAdd,
                  icon: Icons.add_rounded,
                  primaryColor: widget.primaryColor,
                  isAdd: true,
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: widget.primaryColor.withValues(alpha: 0.06),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            child: Column(
              children: [
                for (var i = 0; i < widget.itemCount; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: widget.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: widget.itemBuilder(context, i)),
                      if (isEditingActive) ...[
                        const SizedBox(width: 8),
                        _CompactActionButton(
                          onTap: () => widget.onRemove(i),
                          icon: Icons.remove_rounded,
                          primaryColor: widget.primaryColor,
                          isRemove: true,
                        ),
                      ],
                    ],
                  ),
                  if (i < widget.itemCount - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        height: 1,
                        color: widget.primaryColor.withValues(alpha: 0.05),
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (widget.errorText != null) ...[
            Container(
              height: 1,
              color: widget.primaryColor.withValues(alpha: 0.06),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: const Color(0xFFFF3B30),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color primaryColor;
  final bool isRemove;
  final bool isAdd;

  const _CompactActionButton({
    required this.onTap,
    required this.icon,
    required this.primaryColor,
    this.isRemove = false,
    this.isAdd = false,
  });

  @override
  State<_CompactActionButton> createState() => _CompactActionButtonState();
}

class _CompactActionButtonState extends State<_CompactActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isRemove
        ? const Color(0xFFFF3B30).withValues(alpha: 0.08)
        : widget.isAdd
        ? widget.primaryColor
        : widget.primaryColor.withValues(alpha: 0.08);

    final iconColor = widget.isRemove
        ? const Color(0xFFFF3B30)
        : widget.isAdd
        ? Colors.white
        : widget.primaryColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: !widget.isAdd && !widget.isRemove
                ? Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.15),
                    width: 1,
                  )
                : null,
            boxShadow: widget.isAdd
                ? [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(child: Icon(widget.icon, size: 20, color: iconColor)),
        ),
      ),
    );
  }
}
