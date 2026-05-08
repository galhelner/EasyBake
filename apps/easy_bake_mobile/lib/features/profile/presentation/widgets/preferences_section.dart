import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_preferences_notifier.dart';

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesNotifierProvider);

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
                value: preferences.healthyModeEnabled,
                onChanged: (value) {
                  ref.read(userPreferencesNotifierProvider.notifier).toggleHealthyMode(value);
                },
                activeThumbColor: const Color(0xFF2E4E69),
                activeTrackColor: const Color(0xFF2E4E69).withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
