import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Global notification service initialized once at app startup.
/// Prevents multiple re-initializations that can conflict with iOS push daemon (apsd).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late final FlutterLocalNotificationsPlugin _plugin;

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  FlutterLocalNotificationsPlugin get plugin => _plugin;
  bool get isInitialized => _initialized;
  static bool _initialized = false;

  /// Initialize notifications once at app startup (in main()).
  /// This prevents multiple initializations that can cause iOS apsd conflicts.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _plugin = FlutterLocalNotificationsPlugin();

    // Initialize timezone data
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Schedule a notification with reduced system impact for iOS.
  /// Uses InterruptionLevel.active instead of timeSensitive to avoid
  /// disrupting other apps' push notifications via apsd.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int secondsFromNow,
    String? payload,
    String? channelId,
  }) async {
    if (!_initialized) {
      throw StateError(
        'NotificationService not initialized. Call initialize() in main()',
      );
    }

    if (secondsFromNow <= 0) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'easybake_timer_alerts',
      'Timer Alerts',
      channelDescription: 'Notifications when recipe timers complete',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    /// Using InterruptionLevel.active instead of timeSensitive to reduce
    /// system overhead and prevent iOS apsd daemon conflicts with other apps.
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsFromNow)),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Show an immediate notification.
  /// Uses InterruptionLevel.active to minimize system impact on iOS.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      throw StateError(
        'NotificationService not initialized. Call initialize() in main()',
      );
    }

    const androidDetails = AndroidNotificationDetails(
      'easybake_timer_alerts',
      'Timer Alerts',
      channelDescription: 'Notifications when recipe timers complete',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    /// Using InterruptionLevel.active instead of timeSensitive.
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Cancel a scheduled or pending notification.
  Future<void> cancelNotification(int id) async {
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(id: id);
  }
}
