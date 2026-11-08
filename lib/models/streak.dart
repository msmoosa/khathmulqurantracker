import 'reading_entry.dart';

/// Consecutive days of reading.
class Streak {
  const Streak({
    required this.current,
    required this.best,
    required this.readToday,
  });

  /// Days in a row with reading, up to today. Not reading yet today doesn't
  /// break the streak; it only ends once a whole day passes without reading.
  final int current;
  final int best;
  final bool readToday;
}

Streak readingStreak(List<DailyCount> daily, DateTime now) {
  final read = {
    for (final d in daily)
      if (d.verses > 0) d.day,
  };
  final today = DateTime(now.year, now.month, now.day);
  final readToday = read.contains(today);

  var current = 0;
  var d = readToday ? today : DateTime(today.year, today.month, today.day - 1);
  while (read.contains(d)) {
    current++;
    d = DateTime(d.year, d.month, d.day - 1);
  }

  // daily has one entry per calendar day, so a run of non-zero entries is a
  // run of consecutive days.
  var best = 0;
  var run = 0;
  for (final day in daily) {
    run = day.verses > 0 ? run + 1 : 0;
    if (run > best) best = run;
  }

  return Streak(current: current, best: best, readToday: readToday);
}
