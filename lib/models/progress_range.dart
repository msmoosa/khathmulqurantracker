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

/// One bar in the chart: the verses read over [days] days from [start].
class ChartBucket {
  const ChartBucket(this.start, this.days, this.verses);

  final DateTime start;
  final int days;
  final int verses;

  double get perDay => verses / days;
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
  final counts = {for (final d in daily) d.day: d.verses};
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
    days.add(DailyCount(d, counts[d] ?? 0));
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
      buckets.add(ChartBucket(d.day, 1, d.verses));
    } else {
      final last = buckets.removeLast();
      buckets.add(
        ChartBucket(last.start, last.days + 1, last.verses + d.verses),
      );
    }
  }
  return RangeSummary(days, size, buckets);
}

/// Least-squares line through [ys] at x = 0, 1, 2, ..., or null when there
/// are too few points for a trend to mean anything.
({double intercept, double slope})? linearTrend(List<double> ys) {
  final n = ys.length;
  if (n < 3) return null;
  final meanX = (n - 1) / 2;
  final meanY = ys.fold<double>(0, (sum, y) => sum + y) / n;
  var sxy = 0.0;
  var sxx = 0.0;
  for (var i = 0; i < n; i++) {
    sxy += (i - meanX) * (ys[i] - meanY);
    sxx += (i - meanX) * (i - meanX);
  }
  final slope = sxy / sxx;
  return (intercept: meanY - slope * meanX, slope: slope);
}
