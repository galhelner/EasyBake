import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/models/user_preferences.dart';
import '../providers/user_preferences_notifier.dart';

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
  State<_PreferencesSectionContent> createState() => _PreferencesSectionContentState();
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
      // nothing to save, just close editor
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
      // keep editing state so user can retry; optionally show an error later
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

  @override
  Widget build(BuildContext context) {
    final authState = widget.ref.watch(authNotifierProvider);
    final chatDisplayName = authState.displayName?.trim();
    final hasCustomChatName = chatDisplayName != null && chatDisplayName.isNotEmpty;

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F334A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Customize your experience',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5D7489)),
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              title: const Text(
                'Healthy Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F334A),
                ),
              ),
              subtitle: const Text(
                'Show health badges on recipe cards',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5D7489),
                ),
              ),
              trailing: Switch(
                value: widget.preferences.healthyModeEnabled,
                onChanged: (value) {
                  widget.ref.read(userPreferencesNotifierProvider.notifier).toggleHealthyMode(value);
                },
                activeThumbColor: const Color(0xFF2E4E69),
                activeTrackColor: const Color(0xFF2E4E69).withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Match Healthy Mode style exactly (Container + ListTile)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              title: const Text(
                'Chat Display Name',
                style: TextStyle(
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
                        hintText: 'Enter your chat display name',
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
                          borderSide: const BorderSide(color: Color(0xFFC9D9E8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFC9D9E8)),
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
                        const Text(
                          'This is the name displayed in the community chat',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5D7489),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Prominent pill showing the current display name value
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD7E3EF)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF113257).withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasCustomChatName ? Icons.verified_user_rounded : Icons.person_outline_rounded,
                                size: 16,
                                color: hasCustomChatName ? const Color(0xFF2E6A48) : const Color(0xFF67809A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasCustomChatName ? chatDisplayName : 'Using your full profile name by default',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: hasCustomChatName ? FontWeight.w700 : FontWeight.w600,
                                  color: hasCustomChatName ? const Color(0xFF16344B) : const Color(0xFF667D91),
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
                        icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF2E4E69)),
                        tooltip: 'Edit',
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
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF7A4340)),
                            tooltip: 'Cancel',
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
                                  icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                  tooltip: 'Save',
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
