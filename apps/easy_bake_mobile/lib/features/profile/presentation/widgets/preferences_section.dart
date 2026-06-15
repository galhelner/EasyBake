import 'package:easy_bake_mobile/core/localization/app_locale_controller.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/models/user_preferences.dart';
import '../providers/user_preferences_notifier.dart';

enum _LanguageChoice { system, english, hebrew }

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesNotifierProvider);

    return _PreferencesSectionContent(preferences: preferences, ref: ref);
  }
}

class _PreferencesSectionContent extends StatefulWidget {
  final UserPreferences preferences;
  final WidgetRef ref;

  const _PreferencesSectionContent({
    required this.preferences,
    required this.ref,
  });

  @override
  State<_PreferencesSectionContent> createState() =>
      _PreferencesSectionContentState();
}

class _PreferencesSectionContentState extends State<_PreferencesSectionContent> {
  late TextEditingController _chatDisplayNameController;
  bool _isEditingChatNameActive = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authState = widget.ref.read(authNotifierProvider);
    _chatDisplayNameController = TextEditingController(
      text: authState.displayName ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _PreferencesSectionContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final authState = widget.ref.read(authNotifierProvider);
    final oldAuthState = oldWidget.ref.read(authNotifierProvider);
    if (authState.displayName != oldAuthState.displayName &&
        !_isEditingChatNameActive) {
      _chatDisplayNameController.text = authState.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _chatDisplayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChatDisplayName() async {
    final newName = _chatDisplayNameController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _isEditingChatNameActive = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.ref
          .read(userPreferencesNotifierProvider.notifier)
          .updateChatDisplayName(newName);
      if (!mounted) return;
      setState(() {
        _isEditingChatNameActive = false;
      });
    } catch (_) {
      // Keep editing so the user can retry.
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditingChatNameActive = true;
    });
  }

  void _cancelEditing() {
    final authState = widget.ref.read(authNotifierProvider);
    _chatDisplayNameController.text = authState.displayName ?? '';
    setState(() {
      _isEditingChatNameActive = false;
    });
  }

  void _setLanguageChoice(_LanguageChoice choice) {
    if (choice == _LanguageChoice.system) {
      setAppLocale(null);
      return;
    }

    if (choice == _LanguageChoice.english) {
      setAppLocale(const Locale('en'));
      return;
    }

    setAppLocale(const Locale('he'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = widget.ref.watch(authNotifierProvider);
    final chatDisplayName = authState.displayName?.trim();
    final hasCustomChatName =
        chatDisplayName != null && chatDisplayName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Color(0xFF2E4E69),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.preferencesSectionTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F334A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.customizeYourExperienceSubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5D7489),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                title: Text(
                  l10n.healthyModeTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F334A),
                  ),
                ),
                subtitle: Text(
                  l10n.healthyModeSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5D7489),
                  ),
                ),
                trailing: Switch(
                  value: widget.preferences.healthyModeEnabled,
                  onChanged: (value) {
                    widget.ref
                        .read(userPreferencesNotifierProvider.notifier)
                        .toggleHealthyMode(value);
                  },
                  activeThumbColor: const Color(0xFF2E4E69),
                  activeTrackColor:
                      const Color(0xFF2E4E69).withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              title: Text(
                l10n.chatDisplayNameLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F334A),
                ),
              ),
              subtitle: _isEditingChatNameActive
                  ? TextField(
                      controller: _chatDisplayNameController,
                      maxLength: 50,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: l10n.enterChatDisplayNameHint,
                        hintStyle: const TextStyle(
                          color: Color(0xFF8A9CAF),
                          fontSize: 14,
                        ),
                        counterStyle: const TextStyle(
                          color: Color(0xFF7D90A5),
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF5F7890),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFC9D9E8),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFC9D9E8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E4E69),
                            width: 1.8,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111B26),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.chatDisplayNameDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5D7489),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD7E3EF)),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF113257).withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasCustomChatName
                                    ? Icons.verified_user_rounded
                                    : Icons.person_outline_rounded,
                                size: 16,
                                color: hasCustomChatName
                                    ? const Color(0xFF2E6A48)
                                    : const Color(0xFF67809A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasCustomChatName
                                    ? chatDisplayName
                                    : l10n.usingFullProfileNameByDefaultMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      hasCustomChatName
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                  color: hasCustomChatName
                                      ? const Color(0xFF16344B)
                                      : const Color(0xFF667D91),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              trailing: !_isEditingChatNameActive
                  ? Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FA),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: IconButton(
                        onPressed: _startEditing,
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: Color(0xFF2E4E69),
                        ),
                        tooltip: l10n.editTooltip,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6EAE9),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: IconButton(
                            onPressed: _isSaving ? null : _cancelEditing,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF7A4340),
                            ),
                            tooltip: l10n.cancelTooltip,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E4E69),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: _isSaving
                              ? const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: _saveChatDisplayName,
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  tooltip: l10n.saveTooltip,
                                ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: Color(0xFF2E4E69),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.languageSectionTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F334A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.customizeYourExperienceSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D7489),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ValueListenableBuilder<Locale?>(
                  valueListenable: appLocaleNotifier,
                  builder: (context, locale, _) {
                    final selectedChoice = locale == null
                        ? _LanguageChoice.system
                        : locale.languageCode == 'he'
                            ? _LanguageChoice.hebrew
                            : _LanguageChoice.english;

                    return DropdownMenu<_LanguageChoice>(
                      initialSelection: selectedChoice,
                      expandedInsets: EdgeInsets.zero,
                      width: 240,
                      enableSearch: false,
                      menuHeight: 180,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F334A),
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD7E3EF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD7E3EF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E4E69),
                            width: 1.4,
                          ),
                        ),
                      ),
                      leadingIcon: const Icon(
                        Icons.public_rounded,
                        size: 18,
                        color: Color(0xFF5F7890),
                      ),
                      trailingIcon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF5F7890),
                      ),
                      dropdownMenuEntries: [
                        DropdownMenuEntry<_LanguageChoice>(
                          value: _LanguageChoice.system,
                          label: l10n.languageSystemDefaultLabel,
                          leadingIcon: const Icon(Icons.auto_mode_rounded, size: 18),
                        ),
                        DropdownMenuEntry<_LanguageChoice>(
                          value: _LanguageChoice.english,
                          label: l10n.languageEnglishLabel,
                          leadingIcon: const Icon(Icons.translate_rounded, size: 18),
                        ),
                        DropdownMenuEntry<_LanguageChoice>(
                          value: _LanguageChoice.hebrew,
                          label: l10n.languageHebrewLabel,
                          leadingIcon: const Icon(Icons.translate_rounded, size: 18),
                        ),
                      ],
                      onSelected: (choice) {
                        if (choice == null) {
                          return;
                        }
                        _setLanguageChoice(choice);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
