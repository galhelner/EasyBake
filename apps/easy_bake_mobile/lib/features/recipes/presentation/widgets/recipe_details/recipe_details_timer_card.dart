import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../../../core/services/notification_service.dart';
import 'recipe_details_theme.dart';

class RecipeDetailsTimerCard extends StatefulWidget {
  const RecipeDetailsTimerCard({super.key, required this.instructions});

  final List<String> instructions;

  @override
  State<RecipeDetailsTimerCard> createState() => _RecipeDetailsTimerCardState();
}

class _RecipeDetailsTimerCardState extends State<RecipeDetailsTimerCard>
    with WidgetsBindingObserver {
  static const List<int> _kFallbackMinutes = [15, 30, 45, 60];
  static const _kTimerNotificationId = 4001;

  Timer? _ticker;
  DateTime? _timerEndsAt;
  late List<int> _suggestedSeconds;
  late int _selectedDurationSeconds;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _suggestedSeconds = _buildSuggestedDurations(widget.instructions);
    _selectedDurationSeconds = _suggestedSeconds.first;
    _remainingSeconds = _selectedDurationSeconds;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRunning) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _syncRemainingWithClock(showCompletionDialogIfDone: true);
      if (_isRunning) {
        _startTicker();
      }
      return;
    }

    // STRICTLY cancel ticker when app is not in foreground to prevent
    // background CPU usage and system interference on iOS.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _ticker?.cancel();
      _ticker = null;
    }
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
    _ticker = null;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cancelScheduledCompletionNotification());
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

      final l10n = AppLocalizations.of(context)!;
      if (hours > 0 && minutes > 0) {
        return '$hours${l10n.timerHourUnitShort} $minutes${l10n.timerMinuteUnitShort}';
      }
      if (hours > 0) {
        return '$hours${l10n.timerHourUnitShort}';
      }
      if (duration.inMinutes > 0 && secs > 0) {
        return '${duration.inMinutes}${l10n.timerMinuteUnitShort} $secs${l10n.timerSecondUnitShort}';
      }
      if (duration.inMinutes > 0) {
        return '${duration.inMinutes}${l10n.timerMinuteUnitShort}';
      }
      return '$secs${l10n.timerSecondUnitShort}';
  }

  void _startOrResume() {
    if (_isRunning || _remainingSeconds <= 0) {
      return;
    }

    _timerEndsAt = DateTime.now().add(Duration(seconds: _remainingSeconds));

    // On iOS, schedule the notification and let the OS handle background timing.
    // Don't run the foreground ticker while app is in background.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      unawaited(
        _scheduleCompletionNotification(secondsFromNow: _remainingSeconds),
      );
    }

    setState(() {
      _isRunning = true;
    });

    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = null;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _ticker = null;
        return;
      }

      _syncRemainingWithClock(showCompletionDialogIfDone: true);
    });
  }

  void _syncRemainingWithClock({required bool showCompletionDialogIfDone}) {
    if (!_isRunning) {
      return;
    }

    final endsAt = _timerEndsAt;
    if (endsAt == null) {
      return;
    }

    final millisLeft =
        endsAt.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    if (millisLeft <= 0) {
      _finishTimer(showCompletionDialog: showCompletionDialogIfDone);
      return;
    }

    final nextRemaining = (millisLeft / 1000).ceil();
    if (nextRemaining == _remainingSeconds) {
      return;
    }

    if (mounted) {
      setState(() {
        _remainingSeconds = nextRemaining;
      });
    } else {
      _remainingSeconds = nextRemaining;
    }
  }

  void _finishTimer({required bool showCompletionDialog}) {
    _ticker?.cancel();
    _ticker = null;
    _timerEndsAt = null;
    unawaited(_cancelScheduledCompletionNotification());

    if (mounted) {
      setState(() {
        _isRunning = false;
        _remainingSeconds = _selectedDurationSeconds;
      });
    } else {
      _isRunning = false;
      _remainingSeconds = _selectedDurationSeconds;
    }

    if (showCompletionDialog) {
      unawaited(_showTimerCompleteDialog());
    }
  }

  Future<void> _showTimerCompleteDialog() async {
    final l10n = AppLocalizations.of(context)!;
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
                Text(
                  l10n.timerCompleteTitle,
                  style: const TextStyle(
                    color: kRecipeDetailsPrimaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.timerCompleteMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                    child: Text(l10n.timerCompleteButtonLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scheduleCompletionNotification({
    required int secondsFromNow,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    // Notification plugin is now initialized globally in main().
    // Simply delegate to NotificationService which uses InterruptionLevel.active
    // to reduce system impact and prevent iOS apsd conflicts.
    await NotificationService().scheduleNotification(
      id: _kTimerNotificationId,
      title: l10n.timerNotificationTitle,
      body: l10n.timerNotificationBody,
      secondsFromNow: secondsFromNow,
      payload: 'recipe_timer_done',
    );
  }

  Future<void> _showCompletionNotification() async {
    final l10n = AppLocalizations.of(context)!;
    // Use the globally initialized NotificationService.
    // InterruptionLevel.active is used to minimize system overhead.
    await NotificationService().showNotification(
      id: _kTimerNotificationId,
      title: l10n.timerNotificationTitle,
      body: l10n.timerNotificationBody,
      payload: 'recipe_timer_done',
    );
  }

  Future<void> _cancelScheduledCompletionNotification() async {
    await NotificationService().cancelNotification(_kTimerNotificationId);
  }

  Future<void> _playCompletionFeedback() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
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
    _ticker = null;
    final endsAt = _timerEndsAt;
    if (endsAt != null) {
      final millisLeft =
          endsAt.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
      final computedSeconds = millisLeft <= 0 ? 0 : (millisLeft / 1000).ceil();
      _remainingSeconds = computedSeconds;
    }
    _timerEndsAt = null;
    unawaited(_cancelScheduledCompletionNotification());
    setState(() {
      _isRunning = false;
    });
  }

  void _reset() {
    _ticker?.cancel();
    _ticker = null;
    _timerEndsAt = null;
    unawaited(_cancelScheduledCompletionNotification());
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedDurationSeconds;
    });
  }

  void _pickSuggestion(int seconds) {
    _ticker?.cancel();
    _ticker = null;
    _timerEndsAt = null;
    unawaited(_cancelScheduledCompletionNotification());
    setState(() {
      _isRunning = false;
      _selectedDurationSeconds = seconds;
      _remainingSeconds = seconds;
    });
  }

  Future<void> _openCustomDurationPicker() async {
    final l10n = AppLocalizations.of(context)!;
    int hours = _selectedDurationSeconds ~/ 3600;
    int minutes = (_selectedDurationSeconds % 3600) ~/ 60;
    int seconds = _selectedDurationSeconds % 60;

    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.44,
          minChildSize: 0.32,
          maxChildSize: 0.72,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6FBFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: StatefulBuilder(builder: (context, setSheetState) {
                String preview() {
                  final total = (hours * 3600) + (minutes * 60) + seconds;
                  final d = Duration(seconds: total);
                  if (d.inHours > 0) {
                    final h = d.inHours;
                    final m = d.inMinutes.remainder(60);
                    return '${h}h ${m}m';
                  }
                  if (d.inMinutes > 0) {
                    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s'.replaceAll(RegExp(r' 0s'), '');
                  }
                  return '${d.inSeconds}s';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.timerSetCustomTitle,
                                style: const TextStyle(
                                  color: kRecipeDetailsPrimaryBlue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                preview(),
                                style: const TextStyle(
                                  color: Color(0xFF4A607A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop<int>(null),
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2EEF8)),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: kRecipeDetailsPrimaryBlue,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(initialItem: hours),
                              itemExtent: 34,
                              backgroundColor: Colors.transparent,
                              onSelectedItemChanged: (i) {
                                setSheetState(() => hours = i);
                              },
                              children: List.generate(13, (i) => Center(child: Text('$i', style: const TextStyle(fontSize: 16, color: Color(0xFF172A3E), fontWeight: FontWeight.w500)))),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(initialItem: minutes),
                              itemExtent: 34,
                              backgroundColor: Colors.transparent,
                              onSelectedItemChanged: (i) {
                                setSheetState(() => minutes = i);
                              },
                              children: List.generate(60, (i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 16, color: Color(0xFF172A3E), fontWeight: FontWeight.w500)))),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(initialItem: seconds),
                              itemExtent: 34,
                              backgroundColor: Colors.transparent,
                              onSelectedItemChanged: (i) {
                                setSheetState(() => seconds = i);
                              },
                              children: List.generate(60, (i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 16, color: Color(0xFF172A3E), fontWeight: FontWeight.w500)))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kRecipeDetailsPrimaryBlue,
                              side: const BorderSide(color: Color(0xFFD8E7F4)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(context).pop<int>(null),
                            child: Text(l10n.cancelButtonLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: kRecipeDetailsPrimaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final total = (hours * 3600) + (minutes * 60) + seconds;
                              if (total <= 0) {
                                Navigator.of(context).pop<int>(null);
                                return;
                              }
                              Navigator.of(context).pop<int>(total);
                            },
                            child: Text(l10n.applyButtonLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            );
          },
        );
      },
    );

    if (!mounted || picked == null || picked <= 0) {
      return;
    }

    _ticker?.cancel();
    _ticker = null;
    _timerEndsAt = null;
    unawaited(_cancelScheduledCompletionNotification());
    setState(() {
      _isRunning = false;
      _selectedDurationSeconds = picked;
      _remainingSeconds = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              alignment: Alignment.topLeft,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.timerKitchenTitle,
                                style: const TextStyle(
                                  color: kRecipeDetailsPrimaryBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                l10n.timerKitchenSubtitle,
                                style: const TextStyle(
                                  color: Color(0xFF4A607A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.timerCloseTooltip,
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
                            label: Text(l10n.timerCustomButtonLabel),
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
                            label: Text(
                              _isRunning
                                  ? l10n.timerPauseButtonLabel
                                  : l10n.timerStartButtonLabel,
                            ),
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
                          label: Text(l10n.timerResetButtonLabel),
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
                message: l10n.timerOpenTooltip,
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
