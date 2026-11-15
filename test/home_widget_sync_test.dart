import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/data/surahs.dart';
import 'package:khathmtracker/models/reading_entry.dart';
import 'package:khathmtracker/state/home_widget_sync.dart';

void main() {
  test('khathm percentage runs from the first verse to the last', () {
    expect(khathmPercent(1, 1), 0);
    expect(khathmPercent(2, 255), 4);
    expect(khathmPercent(114, 5), 99);
    expect(khathmPercent(114, 6), 100);
  });

  test('gives the widget its values', () {
    final now = DateTime(2026, 11, 15, 20);
    ReadingEntry at(int day, int surah, int verse) => ReadingEntry(
      surah: surah,
      verse: verse,
      savedAt: DateTime(2026, 11, day, 9),
    );

    expect(HomeWidgetSync.values([], now), {
      'position': null,
      'percent': 0,
      'streak': 0,
      'last_read_day': null,
      'last_read_verses': 0,
    });

    // Read on the 13th, 14th and 15th: a three-day streak up to today.
    final values = HomeWidgetSync.values([
      at(12, 2, 1),
      at(13, 2, 20),
      at(14, 2, 100),
      at(15, 2, 255),
    ], now);
    expect(values, {
      'position': 'Al-Baqarah 2:255',
      'percent': 4,
      'streak': 3,
      'last_read_day': '2026-11-15',
      'last_read_verses': 155,
    });
  });
}
