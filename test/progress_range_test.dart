import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/models/progress_range.dart';
import 'package:khathmtracker/models/reading_entry.dart';
import 'package:khathmtracker/models/streak.dart';

/// [verses] read on consecutive days starting at [start].
List<DailyCount> days(DateTime start, List<int> verses) => [
  for (var i = 0; i < verses.length; i++)
    DailyCount(DateTime(start.year, start.month, start.day + i), verses[i]),
];

void main() {
  final now = DateTime(2026, 11, 8, 14);

  group('summarizeRange', () {
    test('runs to today and starts no earlier than tracking', () {
      final daily = days(DateTime(2026, 11, 4), [10, 0, 20]); // 4th-6th
      final s = summarizeRange(daily, ProgressRange.week, now);
      expect(s.days.first.day, DateTime(2026, 11, 4));
      expect(s.days.last.day, DateTime(2026, 11, 8));
      expect(s.days.length, 5);
      expect(s.total, 30);
      expect(s.average, 6);
      expect(s.size, BucketSize.day);
    });

    test('keeps only the last 7 days', () {
      final daily = days(DateTime(2026, 10, 1), List.filled(39, 1));
      final s = summarizeRange(daily, ProgressRange.week, now);
      expect(s.days.length, 7);
      expect(s.days.first.day, DateTime(2026, 11, 2));
      expect(s.buckets.length, 7);
    });

    test('groups 90 days by week with per-day averages', () {
      final daily = days(DateTime(2026, 8, 1), List.filled(100, 7));
      final s = summarizeRange(daily, ProgressRange.quarter, now);
      expect(s.size, BucketSize.week);
      expect(s.buckets.every((b) => b.perDay == 7), isTrue);
      // Weeks start on Monday, except a partial first one.
      expect(s.buckets[1].start.weekday, DateTime.monday);
      expect(s.buckets.fold<int>(0, (n, b) => n + b.days), 90);
    });

    test('groups a year by month', () {
      final daily = days(DateTime(2025, 1, 1), List.filled(700, 1));
      final s = summarizeRange(daily, ProgressRange.year, now);
      expect(s.size, BucketSize.month);
      expect(s.buckets.length, 13);
    });

    test('is empty without data', () {
      expect(summarizeRange([], ProgressRange.all, now).buckets, isEmpty);
    });
  });

  test('linearTrend fits a straight line', () {
    expect(linearTrend([1, 2]), isNull);
    final t = linearTrend([1, 3, 5, 7])!;
    expect(t.slope, closeTo(2, 1e-9));
    expect(t.intercept, closeTo(1, 1e-9));
  });

  group('readingStreak', () {
    test('counts back from today', () {
      final s = readingStreak(days(DateTime(2026, 11, 5), [5, 5, 5, 5]), now);
      expect(s.current, 4);
      expect(s.readToday, isTrue);
    });

    test('stays alive until a whole day is missed', () {
      final s = readingStreak(days(DateTime(2026, 11, 5), [5, 5, 5]), now);
      expect(s.current, 3);
      expect(s.readToday, isFalse);
    });

    test('breaks on a missed day and remembers the best', () {
      final daily = days(DateTime(2026, 10, 30), [1, 1, 1, 1, 0, 0, 1, 1, 0]);
      final s = readingStreak(daily, now);
      expect(s.current, 0);
      expect(s.best, 4);
    });
  });
}
