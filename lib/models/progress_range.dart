import '../data/quran.dart';
import 'reading_entry.dart';

/// The time windows the Progress screen can show.
enum ProgressRange {
  week('7D', 7),
  month('30D', 30),
  quarter('90D', 90),
  year('1Y', 365),
  all('All', null);

  const ProgressRange(this.label, this.days);

  final String label;

  /// Number of days ending today, or null for everything since tracking began.
  final int? days;
}

/// How many days each bar in the chart covers.
enum BucketSize { day, week, month }

/// One bar in the chart: the verses read over [days] days from [start],
/// and the mushaf pages they cover.
class ChartBucket {
  const ChartBucket(this.start, this.days, this.verses, {this.pages = 0});

  final DateTime start;
  final int days;
  final int verses;
  final double pages;

  double get perDay => verses / days;
  double get pagesPerDay => pages / days;
}

/// Verses read within a [ProgressRange], grouped into chart bars.
class RangeSummary {
  const RangeSummary(this.days, this.size, this.buckets);

  static const empty = RangeSummary([], BucketSize.day, []);

  /// Every day in the range, including days with nothing read.
  final List<DailyCount> days;
  final BucketSize size;
  final List<ChartBucket> buckets;

  int get total => days.fold(0, (sum, d) => sum + d.verses);

  double get average => days.isEmpty ? 0 : total / days.length;
}

/// Cuts [daily] down to [range] ending on [now]'s day.
///
/// The range starts no earlier than the first day of tracking, so days before
/// the user started don't drag the average down, and runs up to today, so
/// recent days without reading count as zero. Short spans get a bar per day;
/// longer ones are grouped by week or month, each bar showing that period's
/// average verses per day.
RangeSummary summarizeRange(
  List<DailyCount> daily,
  ProgressRange range,
  DateTime now,
) {
  if (daily.isEmpty) return RangeSummary.empty;
  final counts = {for (final d in daily) d.day: d};
  final today = DateTime(now.year, now.month, now.day);
  final end = daily.last.day.isAfter(today) ? daily.last.day : today;
  var start = daily.first.day;
  if (range.days case final n?) {
    final from = DateTime(end.year, end.month, end.day - (n - 1));
    if (from.isAfter(start)) start = from;
  }

  final days = <DailyCount>[];
  // Step by calendar day rather than Duration(days: 1) to stay correct
  // across daylight-saving changes.
  for (
    var d = start;
    !d.isAfter(end);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    days.add(counts[d] ?? DailyCount(d, 0));
  }

  final size = days.length <= 31
      ? BucketSize.day
      : days.length <= 186
      ? BucketSize.week
      : BucketSize.month;

  final buckets = <ChartBucket>[];
  DateTime? key;
  for (final d in days) {
    final k = switch (size) {
      BucketSize.day => d.day,
      BucketSize.week => DateTime(
        d.day.year,
        d.day.month,
        d.day.day - (d.day.weekday - 1),
      ),
      BucketSize.month => DateTime(d.day.year, d.day.month),
    };
    if (k != key) {
      key = k;
      // A partial first period starts at the range start, not before it.
      buckets.add(ChartBucket(d.day, 1, d.verses, pages: d.pages));
    } else {
      final last = buckets.removeLast();
      buckets.add(
        ChartBucket(
          last.start,
          last.days + 1,
          last.verses + d.verses,
          pages: last.pages + d.pages,
        ),
      );
    }
  }
  return RangeSummary(days, size, buckets);
}

/// How far through the khathm the reader had reached by the end of each
/// bucket, as a percentage of the mushaf's pages: the last position saved
/// before the bucket ended, or null if nothing had been saved by then.
/// [entries] are oldest first.
List<double?> khathmReached(
  List<ReadingEntry> entries,
  List<ChartBucket> buckets,
) {
  return [
    for (final b in buckets)
      () {
        final end = DateTime(b.start.year, b.start.month, b.start.day + b.days);
        final before = entries.where((e) => e.savedAt.isBefore(end));
        return before.isEmpty
            ? null
            : before.last.pages * 100 / mushafPageCount;
      }(),
  ];
}
