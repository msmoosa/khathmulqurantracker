import '../data/surahs.dart';
import '../models/reading_entry.dart';

/// Build with `--dart-define=DEMO=true` to load sample history for store
/// screenshots. Demo data lives under its own storage key, so real reading
/// history on the device is left untouched.
const kDemoMode = bool.fromEnvironment('DEMO');

/// Tab to open on launch (0 Tracker, 1 Progress, 2 Settings), for taking
/// screenshots of each tab without tapping. Pass `--dart-define=DEMO_TAB=1`.
const kDemoTab = int.fromEnvironment('DEMO_TAB');

/// Verses read on each of the last 14 days (oldest first, today last).
/// A zero is a missed day so the chart looks realistic.
const _dailyVerses = [
  142, 186, 95, 210, 168, 0, 230, 175, 120, 198, 260, 150, 185, 140, //
];

/// Two weeks of saves starting from Al-Fatihah, with some days split into
/// a morning and an evening session.
List<ReadingEntry> demoEntries(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int daysAgo, int hour, int minute) =>
      DateTime(today.year, today.month, today.day - daysAgo, hour, minute);

  var position = 1;
  final entries = [
    ReadingEntry(surah: 1, verse: 1, savedAt: at(_dailyVerses.length, 21, 10)),
  ];
  void add(int verses, DateTime savedAt) {
    position += verses;
    final (surah, verse) = _fromAbsolute(position);
    entries.add(ReadingEntry(surah: surah, verse: verse, savedAt: savedAt));
  }

  for (var i = 0; i < _dailyVerses.length; i++) {
    final verses = _dailyVerses[i];
    if (verses == 0) continue;
    final daysAgo = _dailyVerses.length - 1 - i;
    if (daysAgo == 0) {
      // Keep today's save in the past whenever the screenshot is taken.
      add(verses, now.subtract(const Duration(minutes: 25)));
    } else if (verses >= 180) {
      final morning = verses * 2 ~/ 5;
      add(morning, at(daysAgo, 5, 45 + i % 10));
      add(verses - morning, at(daysAgo, 21, 5 + i * 3));
    } else {
      add(verses, at(daysAgo, 20, 20 + i * 2));
    }
  }
  return entries;
}

(int, int) _fromAbsolute(int absolute) {
  var remaining = absolute;
  for (final s in surahs) {
    if (remaining <= s.verseCount) return (s.number, remaining);
    remaining -= s.verseCount;
  }
  return (114, surahs.last.verseCount);
}
