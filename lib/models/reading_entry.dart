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

/// Verses read on a given calendar day.
class DailyCount {
  const DailyCount(this.day, this.verses);

  final DateTime day;
  final int verses;
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
  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1].absolute;
    final cur = sorted[i].absolute;
    final day = _dateOnly(sorted[i].savedAt);
    totals[day] = (totals[day] ?? 0) + _distance(prev, cur);
  }

  final first = _dateOnly(sorted[1].savedAt);
  final last = _dateOnly(sorted.last.savedAt);
  final result = <DailyCount>[];
  // Step by calendar day rather than Duration(days: 1) to stay correct
  // across daylight-saving changes.
  for (var d = first;
      !d.isAfter(last);
      d = DateTime(d.year, d.month, d.day + 1)) {
    result.add(DailyCount(d, totals[d] ?? 0));
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
