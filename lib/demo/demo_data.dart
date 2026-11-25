import '../data/surahs.dart';
import '../models/reading_entry.dart';

/// Build with `--dart-define=DEMO=true` to load sample history for store
/// screenshots. Demo data lives under its own storage key, so real reading
/// history on the device is left untouched.
const kDemoMode = bool.fromEnvironment('DEMO');

/// Tab to open on launch (0 Read, 1 Tracker, 2 Progress, 3 Settings), for
/// taking screenshots of each tab without tapping. Pass
/// `--dart-define=DEMO_TAB=1`.
const kDemoTab = int.fromEnvironment('DEMO_TAB');

/// Mushaf page to open the reader at on launch. Pass
/// `--dart-define=DEMO_PAGE=604`.
const kDemoPage = int.fromEnvironment('DEMO_PAGE');

/// Verse to hold on launch, as `surah:verse`: opens the reader at its page
/// with its verse menu showing. Pass `--dart-define=DEMO_VERSE=19:6`.
const kDemoVerse = String.fromEnvironment('DEMO_VERSE');

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

  // A first save in the opening surahs counts from the start of the
  // Quran (see dailyCounts), so no baseline save is needed.
  var position = 0;
  final entries = <ReadingEntry>[];
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
