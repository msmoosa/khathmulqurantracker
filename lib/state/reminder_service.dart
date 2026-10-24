import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the daily "recite Quran" reminder and persists its settings.
class ReminderService extends ChangeNotifier {
  ReminderService(this._prefs) {
    _enabled = _prefs.getBool(_enabledKey) ?? true;
    final minutes = _prefs.getInt(_timeKey) ?? defaultTime.hour * 60;
    _time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static const defaultTime = TimeOfDay(hour: 20, minute: 0);

  static const _enabledKey = 'reminder_enabled';
  static const _timeKey = 'reminder_minutes';
  static const _promptedKey = 'reminder_permission_prompted';
  static const _notificationId = 0;

  final SharedPreferences _prefs;
  final _plugin = FlutterLocalNotificationsPlugin();

  late bool _enabled;
  late TimeOfDay _time;

  /// Local notifications are only wired up for the mobile apps.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool get enabled => _enabled;
  TimeOfDay get time => _time;

  /// Whether the explanatory permission dialog has been shown before.
  bool get hasPrompted => _prefs.getBool(_promptedKey) ?? false;

  Future<void> init() async {
    if (!isSupported) return;
    tz.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      // Fall back to UTC; the reminder time would be off but still fire.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested explicitly after the explanatory dialog.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    // Reschedule on every launch so time zone changes are picked up.
    if (hasPrompted) await _reschedule();
  }

  /// Shows the system permission prompt. Returns whether it was granted.
  Future<bool> requestPermission() async {
    await _prefs.setBool(_promptedKey, true);
    if (!isSupported) return false;
    final bool? granted;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true, badge: true);
    } else {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    return granted ?? false;
  }

  /// Records that the user declined the explanatory dialog.
  Future<void> declinePrompt() async {
    await _prefs.setBool(_promptedKey, true);
    await setEnabled(false);
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    await _prefs.setBool(_enabledKey, value);
    await _reschedule();
  }

  Future<void> setTime(TimeOfDay value) async {
    _time = value;
    notifyListeners();
    await _prefs.setInt(_timeKey, value.hour * 60 + value.minute);
    await _reschedule();
  }

  Future<void> _reschedule() async {
    if (!isSupported) return;
    await _plugin.cancel(id: _notificationId);
    if (!_enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Time to recite the Quran',
      body: 'Continue your khathm and log where you reach today.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: 'Daily reminder to recite the Quran',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
