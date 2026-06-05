import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.isConnecting,
    required this.onSend,
    required this.onShareRecipe,
  });

  final TextEditingController controller;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onSend;
  final VoidCallback onShareRecipe;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  static const String _aiChefMentionHandle = 'aichef';

  final GlobalKey _fieldKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  String _previousText = '';
  bool _isMentionPopupOpen = false;
  OverlayEntry? _mentionPopupEntry;

  @override
  void initState() {
    super.initState();
    _previousText = widget.controller.text;
    widget.controller.addListener(_handleComposerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleComposerChanged);
      _previousText = widget.controller.text;
      widget.controller.addListener(_handleComposerChanged);
    }
  }

  @override
  void dispose() {
    _dismissMentionPopup();
    widget.controller.removeListener(_handleComposerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _dismissMentionPopup();
    }
  }

  void _handleComposerChanged() {
    if (!mounted) {
      return;
    }

    final currentText = widget.controller.text;
    if (currentText == _previousText) {
      return;
    }

    _previousText = currentText;

    final mentionQuery = _getActiveMentionQuery(widget.controller.value);
    final shouldShowMentionPopup = _shouldShowMentionPopup(mentionQuery);

    if (_isMentionPopupOpen && !shouldShowMentionPopup) {
      _dismissMentionPopup();
      return;
    }

    if (_isMentionPopupOpen || !shouldShowMentionPopup) {
      return;
    }

    unawaited(_showMentionPopup());
  }

  String? _getActiveMentionQuery(TextEditingValue value) {
    final text = value.text;
    final selectionEnd = value.selection.extentOffset;
    if (selectionEnd < 0 || selectionEnd > text.length) {
      return null;
    }

    final textBeforeCursor = text.substring(0, selectionEnd);
    final mentionStart = textBeforeCursor.lastIndexOf('@');
    if (mentionStart == -1) {
      return null;
    }

    if (mentionStart > 0 && !RegExp(r'\s').hasMatch(textBeforeCursor[mentionStart - 1])) {
      return null;
    }

    return text.substring(mentionStart + 1, selectionEnd);
  }

  bool _shouldShowMentionPopup(String? query) {
    if (query == null) {
      return false;
    }

    final normalizedQuery = query.toLowerCase();
    return normalizedQuery != _aiChefMentionHandle &&
        _aiChefMentionHandle.startsWith(normalizedQuery);
  }

  Future<void> _showMentionPopup() async {
    if (!mounted) {
      return;
    }

    final fieldContext = _fieldKey.currentContext;
    final fieldBox = fieldContext?.findRenderObject() as RenderBox?;

    if (fieldBox == null) {
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;

    if (overlayBox == null) {
      return;
    }

    final fieldOrigin = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final fieldBottom = fieldOrigin.dy + fieldBox.size.height;
    const popupWidth = 260.0;
    const popupHeight = 72.0;
    const gap = 8.0;

    final left = (fieldOrigin.dx).clamp(
      12.0,
      overlayBox.size.width - popupWidth - 12.0,
    );
    final aboveTop = fieldOrigin.dy - popupHeight - gap;
    final belowTop = fieldBottom + gap;
    final top = aboveTop >= 12.0 ? aboveTop : belowTop;

    setState(() {
      _isMentionPopupOpen = true;
    });

    _mentionPopupEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissMentionPopup,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: popupWidth,
              child: Material(
                color: Colors.transparent,
                child: _MentionPopupCard(
                  onTap: _selectAiChefMention,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_mentionPopupEntry!);
  }

  void _selectAiChefMention() {
    final value = widget.controller.value;
    final selectionEnd = value.selection.extentOffset;
    if (selectionEnd < 0 || selectionEnd > value.text.length) {
      _dismissMentionPopup();
      return;
    }

    final textBeforeCursor = value.text.substring(0, selectionEnd);
    final mentionStart = textBeforeCursor.lastIndexOf('@');
    if (mentionStart == -1 ||
        (mentionStart > 0 && !RegExp(r'\s').hasMatch(textBeforeCursor[mentionStart - 1]))) {
      _dismissMentionPopup();
      return;
    }

    final updatedText = value.text.replaceRange(
      mentionStart,
      selectionEnd,
      '@$_aiChefMentionHandle',
    );

    widget.controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset: mentionStart + _aiChefMentionHandle.length + 1,
      ),
      composing: TextRange.empty,
    );

    _previousText = updatedText;
    _dismissMentionPopup();
    _focusNode.requestFocus();
  }

  void _dismissMentionPopup() {
    _mentionPopupEntry?.remove();
    _mentionPopupEntry = null;
    if (mounted && _isMentionPopupOpen) {
      setState(() {
        _isMentionPopupOpen = false;
      });
    } else {
      _isMentionPopupOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB).withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(
              color: const Color(0xFFCCD9E8).withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD4E0EE), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF113257).withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.controller,
                        builder: (context, value, _) {
                          final hasText = value.text.trim().isNotEmpty;
                          final maxLines = hasText ? 4 : 5;
                          final textDirection = _resolveTextDirection(
                            context,
                            value.text,
                          );

                          return TextField(
                            key: _fieldKey,
                            controller: widget.controller,
                            focusNode: _focusNode,
                            enabled: widget.isConnected,
                            textDirection: textDirection,
                            keyboardType: TextInputType.multiline,
                            maxLines: maxLines,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              prefixIconConstraints: BoxConstraints(
                                minWidth: hasText ? 36 : 40,
                                minHeight: hasText ? 36 : 40,
                              ),
                              prefixIcon: Center(
                                widthFactor: 1,
                                heightFactor: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    right: 6,
                                  ),
                                  child: Semantics(
                                    label: widget.isConnected
                                        ? l10n.shareRecipeWithCommunityLabel
                                        : l10n.connectToShareRecipesLabel,
                                    button: true,
                                    enabled: widget.isConnected,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: widget.isConnected
                                            ? widget.onShareRecipe
                                            : null,
                                        customBorder: const CircleBorder(),
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: widget.isConnected
                                                ? const Color(0xFFE7F1FF)
                                                : const Color(0xFFF3F6FA),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: widget.isConnected
                                                  ? const Color(0xFFB9D5FF)
                                                  : const Color(0xFFD6E1ED),
                                              width: 1,
                                            ),
                                            boxShadow: widget.isConnected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF1F6FC9,
                                                      ).withValues(alpha: 0.12),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ]
                                                : const [],
                                          ),
                                          child: Icon(
                                            Icons.attach_file_rounded,
                                            size: 16,
                                            color: widget.isConnected
                                                ? const Color(0xFF1F6FC9)
                                                : const Color(0xFF8D9BAD),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                                hintText: widget.isConnecting
                                  ? l10n.composerConnectingHint
                                  : widget.isConnected
                                  ? l10n.composerShareHint
                                  : l10n.composerOfflineHint,
                              hintStyle: const TextStyle(
                                color: Color(0xFF7A8EA4),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: hasText ? 8 : 12,
                              ),
                              isDense: true,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF111B26),
                              height: 1.35,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.controller,
                      builder: (context, value, _) {
                        final canSend =
                            value.text.trim().isNotEmpty && widget.isConnected;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeInOut,
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: canSend
                                ? const Color(0xFF1F6FC9)
                                : const Color(0xFFD8E1EB),
                          ),
                          child: Center(
                            child: IconButton(
                              // Disable Material tooltip: this button lives inside a
                              // ValueListenableBuilder that rebuilds on every keystroke.
                              // Default IconButton tooltips use RawTooltip + a single ticker;
                              // rapid rebuilds can throw "multiple tickers were created".
                              tooltip: '',
                              onPressed: canSend ? widget.onSend : null,
                              icon: Icon(
                                Icons.arrow_upward_rounded,
                                color: canSend
                                    ? Colors.white
                                    : const Color(0xFF8D9BAD),
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        );
                      },
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

TextDirection _resolveTextDirection(BuildContext context, String text) {
  final strongDirection = RegExp(r'[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
  if (strongDirection.hasMatch(text)) {
    return TextDirection.rtl;
  }

  return Directionality.of(context);
}

class MentionTextEditingController extends TextEditingController {
  static const String aiChefMention = '@aichef';

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final mentionStyle = baseStyle.copyWith(
      color: const Color(0xFF1F6FC9),
      fontWeight: FontWeight.w700,
    );

    final text = value.text;
    if (text.isEmpty) {
      return TextSpan(style: baseStyle, text: text);
    }

    final spans = <InlineSpan>[];
    var index = 0;

    while (index < text.length) {
      final mentionIndex = text.indexOf(aiChefMention, index);
      if (mentionIndex == -1) {
        spans.add(TextSpan(text: text.substring(index)));
        break;
      }

      if (mentionIndex > index) {
        spans.add(TextSpan(text: text.substring(index, mentionIndex)));
      }

      final mentionEnd = mentionIndex + aiChefMention.length;

      spans.add(
        TextSpan(
          text: aiChefMention,
          style: mentionStyle,
        ),
      );
      index = mentionEnd;
    }

    return TextSpan(style: baseStyle, children: spans);
  }
}

class _MentionPopupCard extends StatelessWidget {
  const _MentionPopupCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E3EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF113257).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: ClipOval(
                  child: Image.asset(
                    'assets/ai_chef_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.aiChefPopupTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
