import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'recipe_details_theme.dart';

class RecipeDetailsTimerCard extends StatefulWidget {
  const RecipeDetailsTimerCard({super.key, required this.instructions});

  final List<String> instructions;

  @override
  State<RecipeDetailsTimerCard> createState() => _RecipeDetailsTimerCardState();
}

class _RecipeDetailsTimerCardState extends State<RecipeDetailsTimerCard> {
  static const List<int> _kFallbackMinutes = [15, 30, 45, 60];
  static const _kTimerNotificationId = 4001;
  static const _kTimerNotificationChannelId = 'easybake_timer_alerts';
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;

  Timer? _ticker;
  late List<int> _suggestedSeconds;
  late int _selectedDurationSeconds;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _suggestedSeconds = _buildSuggestedDurations(widget.instructions);
    _selectedDurationSeconds = _suggestedSeconds.first;
    _remainingSeconds = _selectedDurationSeconds;
    unawaited(_initializeNotifications());
  }

  @override
  void didUpdateWidget(covariant RecipeDetailsTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameInstructions(oldWidget.instructions, widget.instructions)) {
      return;
    }

    final nextSuggestions = _buildSuggestedDurations(widget.instructions);
    final wasUsingCustom = !_suggestedSeconds.contains(
      _selectedDurationSeconds,
    );
    final nextSelected = wasUsingCustom
        ? _selectedDurationSeconds
        : nextSuggestions.first;

    setState(() {
      _suggestedSeconds = nextSuggestions;
      _selectedDurationSeconds = nextSelected;
      if (!_isRunning) {
        _remainingSeconds = _selectedDurationSeconds;
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool _sameInstructions(List<String> a, List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  List<int> _buildSuggestedDurations(List<String> instructions) {
    final values = <int>{};

    final joinedText = instructions.join(' ').toLowerCase();

    final combinedTime = RegExp(
      r'(\d+)\s*(?:hours?|hrs?|hr|h)\s*(\d+)\s*(?:minutes?|mins?|min|m)',
      caseSensitive: false,
    );
    for (final match in combinedTime.allMatches(joinedText)) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = (hours * 3600) + (minutes * 60);
      if (seconds > 0) {
        values.add(seconds);
      }
    }

    final minuteSecondTime = RegExp(
      r'(\d+)\s*(?:minutes?|mins?|min|m)\s*(\d+)\s*(?:seconds?|secs?|sec|s)',
      caseSensitive: false,
    );
    for (final match in minuteSecondTime.allMatches(joinedText)) {
      final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
      final totalSeconds = (minutes * 60) + seconds;
      if (totalSeconds > 0) {
        values.add(totalSeconds);
      }
    }

    final hourRegex = RegExp(
      r'(\d+)\s*(?:hours?|hrs?|hr|h)',
      caseSensitive: false,
    );
    for (final match in hourRegex.allMatches(joinedText)) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (hours > 0) {
        values.add(hours * 3600);
      }
    }

    final minuteRegex = RegExp(
      r'(\d+)\s*(?:minutes?|mins?|min|m)',
      caseSensitive: false,
    );
    for (final match in minuteRegex.allMatches(joinedText)) {
      final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (minutes > 0) {
        values.add(minutes * 60);
      }
    }

    final secondRegex = RegExp(
      r'(\d+)\s*(?:seconds?|secs?|sec|s)',
      caseSensitive: false,
    );
    for (final match in secondRegex.allMatches(joinedText)) {
      final seconds = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (seconds > 0) {
        values.add(seconds);
      }
    }

    if (values.isEmpty) {
      return _kFallbackMinutes.map((m) => m * 60).toList(growable: false);
    }

    final sorted = values.toList()..sort();
    if (sorted.length > 6) {
      return sorted.sublist(0, 6);
    }
    return sorted;
  }

  String _formatClock(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds.clamp(0, 864000));
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatChipLabel(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    if (duration.inMinutes > 0 && secs > 0) {
      return '${duration.inMinutes}m ${secs}s';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inSeconds}s';
  }

  void _startOrResume() {
    if (_isRunning || _remainingSeconds <= 0) {
      return;
    }

    setState(() {
      _isRunning = true;
    });

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _remainingSeconds = _selectedDurationSeconds;
        });
        _showTimerCompleteDialog();
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  Future<void> _showTimerCompleteDialog() async {
    await _showCompletionNotification();
    await _playCompletionFeedback();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCFE1F3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFDAECFB),
                    border: Border.all(color: const Color(0xFF9EC3E4)),
                  ),
                  child: const Icon(
                    Icons.celebration_outlined,
                    color: kRecipeDetailsPrimaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Timer Complete!',
                  style: TextStyle(
                    color: kRecipeDetailsPrimaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your step is ready for the next action.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4A607A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kRecipeDetailsPrimaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Great'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notificationsPlugin.initialize(settings: settings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _notificationsInitialized = true;
  }

  Future<void> _showCompletionNotification() async {
    await _initializeNotifications();

    const android = AndroidNotificationDetails(
      _kTimerNotificationChannelId,
      'Timer Alerts',
      channelDescription: 'Notifications when recipe timers complete',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notificationsPlugin.show(
      id: _kTimerNotificationId,
      title: 'EasyBake Timer Done',
      body: 'Your timer has finished. Check your recipe step.',
      notificationDetails: const NotificationDetails(
        android: android,
        iOS: ios,
      ),
    );
  }

  Future<void> _playCompletionFeedback() async {
    try {
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.notification,
        ios: IosSounds.glass,
        looping: false,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
        await Vibration.vibrate(
          pattern: const [0, 180, 90, 220, 90, 320],
          amplitude: hasAmplitudeControl ? 200 : -1,
        );
        return;
      }
    } catch (_) {
      // Fall back to basic haptics below.
    }

    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
  }

  void _pause() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedDurationSeconds;
    });
  }

  void _pickSuggestion(int seconds) {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _selectedDurationSeconds = seconds;
      _remainingSeconds = seconds;
    });
  }

  Future<void> _openCustomDurationPicker() async {
    int hours = _selectedDurationSeconds ~/ 3600;
    int minutes = (_selectedDurationSeconds % 3600) ~/ 60;
    int seconds = _selectedDurationSeconds % 60;

    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFFF6FBFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Set custom timer',
                      style: TextStyle(
                        color: kRecipeDetailsPrimaryBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: hours,
                            decoration: const InputDecoration(
                              labelText: 'Hours',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(
                              13,
                              (i) =>
                                  DropdownMenuItem(value: i, child: Text('$i')),
                            ),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setSheetState(() {
                                hours = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: minutes,
                            decoration: const InputDecoration(
                              labelText: 'Minutes',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(
                              60,
                              (i) =>
                                  DropdownMenuItem(value: i, child: Text('$i')),
                            ),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setSheetState(() {
                                minutes = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: seconds,
                            decoration: const InputDecoration(
                              labelText: 'Seconds',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(
                              60,
                              (i) =>
                                  DropdownMenuItem(value: i, child: Text('$i')),
                            ),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setSheetState(() {
                                seconds = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kRecipeDetailsPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          final total =
                              (hours * 3600) + (minutes * 60) + seconds;
                          if (total <= 0) {
                            Navigator.of(context).pop<int>(null);
                            return;
                          }
                          Navigator.of(context).pop<int>(total);
                        },
                        child: const Text('Apply timer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || picked == null || picked <= 0) {
      return;
    }

    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _selectedDurationSeconds = picked;
      _remainingSeconds = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _selectedDurationSeconds == 0
        ? 0.0
        : (_remainingSeconds / _selectedDurationSeconds).clamp(0.0, 1.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final size = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: fade,
          child: SizeTransition(
            sizeFactor: size,
            axisAlignment: -1,
            child: ScaleTransition(
              alignment: Alignment.topLeft,
              scale: Tween<double>(begin: 0.98, end: 1).animate(size),
              child: child,
            ),
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            // ignore: use_null_aware_elements
            if (currentChild case final child?) child,
          ],
        );
      },
      child: _isExpanded
          ? RepaintBoundary(
              key: const ValueKey('timer-expanded'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6F2FF), Color(0xFFF8FCFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBCD6EE)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: kRecipeDetailsPrimaryBlue.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            color: kRecipeDetailsPrimaryBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kitchen Timer',
                                style: TextStyle(
                                  color: kRecipeDetailsPrimaryBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Perfect for proofing, resting, and baking',
                                style: TextStyle(
                                  color: Color(0xFF4A607A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close timer',
                          onPressed: () {
                            setState(() {
                              _isExpanded = false;
                            });
                          },
                          icon: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFC7D9EC),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: kRecipeDetailsPrimaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        _formatClock(_remainingSeconds),
                        style: const TextStyle(
                          color: kRecipeDetailsPrimaryBlue,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: progress,
                        backgroundColor: const Color(0xFFD8E6F3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6A9CC8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final seconds in _suggestedSeconds) ...[
                            ChoiceChip(
                              label: Text(_formatChipLabel(seconds)),
                              selected: _selectedDurationSeconds == seconds,
                              selectedColor: const Color(0xFFB4D3EC),
                              labelStyle: TextStyle(
                                color: _selectedDurationSeconds == seconds
                                    ? kRecipeDetailsPrimaryBlue
                                    : const Color(0xFF4A607A),
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) => _pickSuggestion(seconds),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ActionChip(
                            label: const Text('Custom'),
                            avatar: const Icon(
                              Icons.edit_calendar_outlined,
                              size: 18,
                            ),
                            onPressed: _openCustomDurationPicker,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: kRecipeDetailsPrimaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isRunning ? _pause : _startOrResume,
                            icon: Icon(
                              _isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(_isRunning ? 'Pause' : 'Start'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kRecipeDetailsPrimaryBlue,
                            side: const BorderSide(color: Color(0xFF9AB8D3)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _reset,
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              key: const ValueKey('timer-collapsed'),
              padding: const EdgeInsets.only(bottom: 18),
              child: Tooltip(
                message: 'Open timer',
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() {
                      _isExpanded = true;
                    });
                  },
                  child: Ink(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1EFFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF9EC3E4)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.timer_outlined,
                            color: kRecipeDetailsPrimaryBlue,
                            size: 24,
                          ),
                        ),
                        if (_isRunning)
                          Positioned(
                            right: 7,
                            top: 7,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2DBF6A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
