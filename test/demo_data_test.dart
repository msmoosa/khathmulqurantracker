import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/data/surahs.dart';
import 'package:khathmtracker/demo/demo_data.dart';
import 'package:khathmtracker/models/reading_entry.dart';

void main() {
  test('demo data covers two weeks ending today', () {
    final now = DateTime(2026, 10, 23, 14, 30);
    final entries = demoEntries(now);
    final daily = dailyCounts(entries);

    expect(daily, hasLength(14));
    expect(daily.last.day, DateTime(2026, 10, 23));
    expect(daily.last.verses, 140);
    expect(daily.where((d) => d.verses == 0), hasLength(1));
    expect(entries.every((e) => !e.savedAt.isAfter(now)), isTrue);
    for (final e in entries) {
      expect(e.verse, inInclusiveRange(1, surahs[e.surah - 1].verseCount));
    }
  });
}
