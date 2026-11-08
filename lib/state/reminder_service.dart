import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/reminder_messages.dart';
import '../models/streak.dart';
import 'tracker_store.dart';

/// Schedules the daily "recite Quran" reminder and persists its settings.
///
/// The reminder adapts to the tracker: rather than one repeating
/// notification, each of the next [_daysAhead] days gets its own, with its
/// own saying, and today's is left out once something has been saved today.
/// The schedule is rebuilt whenever the tracker changes and on every launch.
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

  /// How many days of reminders are scheduled ahead. They run out if the app
  /// isn't opened for this long; iOS allows at most 64 pending.
  static const _daysAhead = 30;

  final SharedPreferences _prefs;
  final _plugin = FlutterLocalNotificationsPlugin();
  TrackerStore? _tracker;
  bool _ready = false;
  Future<void> _scheduling = Future.value();

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
    _ready = true;
    // Reschedule on every launch so time zone changes are picked up and the
    // days ahead are topped up.
    if (hasPrompted) await _reschedule();
  }

  /// Skips the reminder on days with a save in [tracker], and keeps the
  /// schedule in step as it changes.
  void watch(TrackerStore tracker) {
    _tracker?.removeListener(_reschedule);
    _tracker = tracker..addListener(_reschedule);
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

  /// Rebuilds the schedule. Calls are queued so overlapping ones can't
  /// interleave their cancel and schedule steps.
  Future<void> _reschedule() =>
      _scheduling = _scheduling.then((_) => _schedule()).catchError((Object e) {
        debugPrint('Reminder scheduling failed: $e');
      });

  Future<void> _schedule() async {
    if (!isSupported || !_ready) return;
    await _plugin.cancelAll();
    if (!_enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final tracker = _tracker;
    final savedToday =
        tracker?.entries.any(
          (e) =>
              DateTime(e.savedAt.year, e.savedAt.month, e.savedAt.day) == today,
        ) ??
        false;
    final streak = tracker == null
        ? 0
        : readingStreak(tracker.daily, now).current;

    var first = true;
    for (var i = 0; i < _daysAhead; i++) {
      final at = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + i,
        _time.hour,
        _time.minute,
      );
      if (!at.isAfter(now) || (i == 0 && savedToday)) continue;
      // Only the next reminder knows the streak it would protect.
      final message = reminderFor(at, streak: first ? streak : 0);
      first = false;
      await _plugin.zonedSchedule(
        id: i,
        title: message.title,
        body: message.body,
        scheduledDate: at,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily reminder',
            channelDescription: 'Daily reminder to recite the Quran',
            styleInformation: BigTextStyleInformation(message.body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
