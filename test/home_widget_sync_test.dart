import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/data/quran.dart';
import 'package:khathmtracker/models/reading_entry.dart';
import 'package:khathmtracker/state/home_widget_sync.dart';

void main() {
  test('khathm progress is counted in mushaf pages', () {
    // Page 1 is Al-Fatihah 1-7, page 2 Al-Baqarah 1-5.
    expect(pagesRead(1, 7), 1);
    expect(pagesRead(2, 5), 2);
    expect(pagesRead(2, 3), closeTo(1.6, 1e-9));
    expect(pagesRead(114, 6), mushafPageCount);

    expect(khathmPercent(1, 1), 0);
    // On page 42: between 41 and 42 of 604 pages.
    expect(khathmPercent(2, 255), 6);
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

    // A baseline on the 12th, then read on the 13th, 14th and 15th: a
    // three-day streak up to today.
    final values = HomeWidgetSync.values([
      at(11, 18, 1),
      at(12, 2, 1),
      at(13, 2, 20),
      at(14, 2, 100),
      at(15, 2, 255),
    ], now);
    expect(values, {
      'position': 'Al-Baqarah 2:255',
      'percent': 6,
      'streak': 3,
      'last_read_day': '2026-11-15',
      'last_read_verses': 155,
    });
  });
}
