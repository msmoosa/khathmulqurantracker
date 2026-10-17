import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/data/surahs.dart';
import 'package:khathmtracker/models/reading_entry.dart';

ReadingEntry e(int surah, int verse, DateTime at) =>
    ReadingEntry(surah: surah, verse: verse, savedAt: at);

void main() {
  test('surah data covers the whole Quran', () {
    expect(surahs.length, 114);
    expect(totalVerses, 6236);
    expect(absoluteVerse(1, 1), 1);
    expect(absoluteVerse(2, 1), 8);
    expect(absoluteVerse(114, 6), 6236);
  });

  test('first entry is only a baseline', () {
    expect(dailyCounts([e(18, 50, DateTime(2026, 10, 1))]), isEmpty);
  });

  test('counts verses between saves and groups by day', () {
    final counts = dailyCounts([
      e(2, 100, DateTime(2026, 10, 1, 8)), // baseline, skipped
      e(2, 150, DateTime(2026, 10, 2, 8)), // +50
      e(2, 160, DateTime(2026, 10, 2, 20)), // +10
      e(3, 1, DateTime(2026, 10, 4, 9)), // +126 (286 - 160) + 1
    ]);
    expect(counts.map((c) => c.verses), [60, 0, 127]);
    expect(counts.first.day, DateTime(2026, 10, 2));
    expect(counts.last.day, DateTime(2026, 10, 4));
  });

  test('wrapping from the end to the start counts as a new khathm', () {
    final counts = dailyCounts([
      e(114, 1, DateTime(2026, 10, 1)),
      e(1, 7, DateTime(2026, 10, 2)),
    ]);
    // 114:2-6 then 1:1-7.
    expect(counts.single.verses, 5 + 7);
  });

  test('a backwards correction counts as zero', () {
    final counts = dailyCounts([
      e(10, 50, DateTime(2026, 10, 1)),
      e(10, 40, DateTime(2026, 10, 2)),
    ]);
    expect(counts.single.verses, 0);
  });
}
