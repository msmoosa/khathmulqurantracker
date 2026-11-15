import '../data/quran.dart';
import '../data/surahs.dart';

/// A saved reading position at a point in time.
class ReadingEntry {
  const ReadingEntry({
    required this.surah,
    required this.verse,
    required this.savedAt,
  });

  final int surah;
  final int verse;
  final DateTime savedAt;

  int get absolute => absoluteVerse(surah, verse);

  /// Mushaf pages read by the end of this position; see [pagesRead].
  double get pages => pagesRead(surah, verse);

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'verse': verse,
    'savedAt': savedAt.toIso8601String(),
  };

  factory ReadingEntry.fromJson(Map<String, dynamic> json) => ReadingEntry(
    surah: json['surah'] as int,
    verse: json['verse'] as int,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}

/// Verses read on a given calendar day, and the mushaf pages they cover.
class DailyCount {
  const DailyCount(this.day, this.verses, {this.pages = 0});

  final DateTime day;
  final int verses;
  final double pages;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Turns the saved positions into verses read per day.
///
/// Each entry contributes the distance from the previous entry. The first
/// entry has no predecessor, so it only sets the baseline (the user may
/// start tracking mid-Quran). Moving backwards past the start is treated as
/// finishing a khathm and starting again; any other backward move counts as
/// zero. Days between the first and last reading with no saves are filled
/// with zero so the chart shows gaps.
List<DailyCount> dailyCounts(List<ReadingEntry> entries) {
  if (entries.length < 2) return const [];
  final sorted = [...entries]..sort((a, b) => a.savedAt.compareTo(b.savedAt));

  final totals = <DateTime, int>{};
  final pages = <DateTime, double>{};
  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    final day = _dateOnly(cur.savedAt);
    final verses = _distance(prev.absolute, cur.absolute);
    totals[day] = (totals[day] ?? 0) + verses;
    pages[day] = (pages[day] ?? 0) + _pageDistance(prev, cur, verses);
  }

  final first = _dateOnly(sorted[1].savedAt);
  final last = _dateOnly(sorted.last.savedAt);
  final result = <DailyCount>[];
  // Step by calendar day rather than Duration(days: 1) to stay correct
  // across daylight-saving changes.
  for (
    var d = first;
    !d.isAfter(last);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    result.add(DailyCount(d, totals[d] ?? 0, pages: pages[d] ?? 0));
  }
  return result;
}

int _distance(int prev, int cur) {
  if (cur >= prev) return cur - prev;
  // Wrapped around: finished the Quran and began a new khathm. Only treat it
  // that way when the jump lands near the start; otherwise it is a correction.
  final wrapped = (totalVerses - prev) + cur;
  return wrapped < totalVerses ~/ 2 ? wrapped : 0;
}

/// Pages read between two positions, [verses] apart by [_distance], which
/// decides whether a backward move began a new khathm.
double _pageDistance(ReadingEntry prev, ReadingEntry cur, int verses) {
  if (verses == 0) return 0;
  if (cur.absolute >= prev.absolute) return cur.pages - prev.pages;
  return mushafPageCount - prev.pages + cur.pages;
}
