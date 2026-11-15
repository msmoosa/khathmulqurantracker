import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../data/surahs.dart';
import '../models/reading_entry.dart';
import '../models/streak.dart';
import 'tracker_store.dart';

/// Keeps the home screen widget showing the latest progress.
///
/// The widget can't run Dart, so it gets plain values: where the reader is
/// up to, how far through the khathm, and the streak along with the day it
/// was counted up to, so the widget can tell for itself when a new day has
/// begun or the streak has lapsed.
class HomeWidgetSync {
  HomeWidgetSync(this._tracker);

  /// Shared with the iOS widget extension.
  static const appGroupId = 'group.com.khathmulqurantracker';

  /// The iOS widget's kind and the Android widget's provider class.
  static const iOSName = 'KhathmWidget';
  static const androidName = 'KhathmWidgetProvider';

  /// The link a widget tap opens: the reader at the tracked verse.
  static final continueUri = Uri.parse('khathmtracker://continue');

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  final TrackerStore _tracker;

  /// Taps on the widget: the one that launched the app, if any, then each
  /// one while it runs.
  static Stream<Uri> taps() async* {
    final launch = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (launch != null) yield launch;
    await for (final uri in HomeWidget.widgetClicked) {
      if (uri != null) yield uri;
    }
  }

  Future<void> start() async {
    if (!isSupported) return;
    await HomeWidget.setAppGroupId(appGroupId);
    _tracker.addListener(_push);
    await _push();
  }

  /// Values for the widget, given the reading history and the time now.
  static Map<String, Object?> values(List<ReadingEntry> entries, DateTime now) {
    final daily = dailyCounts(entries);
    final streak = readingStreak(daily, now);
    final last = entries.isEmpty ? null : entries.last;
    final readDays = daily.where((d) => d.verses > 0);
    final lastDay = readDays.isEmpty ? null : readDays.last;
    return {
      'position': last == null
          ? null
          : '${surahs[last.surah - 1].name} ${last.surah}:${last.verse}',
      'percent': last == null ? 0 : khathmPercent(last.surah, last.verse),
      // The streak runs up to the last day read; the widget counts it as
      // current while that day is today or yesterday.
      'streak': streak.current,
      'last_read_day': lastDay == null ? null : _day(lastDay.day),
      'last_read_verses': lastDay?.verses ?? 0,
    };
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _push() async {
    try {
      for (final MapEntry(:key, :value) in values(
        _tracker.entries,
        DateTime.now(),
      ).entries) {
        await HomeWidget.saveWidgetData(key, value);
      }
      await HomeWidget.updateWidget(iOSName: iOSName, androidName: androidName);
    } catch (e) {
      // Never let the widget get in the way of saving progress.
      debugPrint('Home widget update failed: $e');
    }
  }
}
