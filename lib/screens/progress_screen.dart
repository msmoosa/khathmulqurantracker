import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../models/progress_range.dart';
import '../models/reading_entry.dart';
import '../models/streak.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../util/format.dart';
import '../widgets/islamic_patterns.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.store});

  final TrackerStore store;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressRange _range = ProgressRange.week;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final theme = Theme.of(context);
        final now = DateTime.now();
        final daily = store.daily;
        final summary = summarizeRange(daily, _range, now);
        final history = store.entries.reversed.toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (store.entries.isNotEmpty) ...[
              _StreakCard(daily: daily, now: now),
              const SizedBox(height: 16),
            ],
            if (daily.isNotEmpty) ...[
              SegmentedButton<ProgressRange>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: [
                  for (final r in ProgressRange.values)
                    ButtonSegment(value: r, label: Text(r.label)),
                ],
                selected: {_range},
                onSelectionChanged: (s) => setState(() => _range = s.single),
              ),
              const SizedBox(height: 16),
            ],

            // Stats row
            _Stats(daily: daily, summary: summary, now: now),
            const SizedBox(height: 16),

            // Chart card
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 12),
                      child: Text(
                        'Verses per Day',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    daily.isEmpty
                        ? SizedBox(
                            height: 180,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  'Save your position on at least two occasions '
                                  'to see daily verses read.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : _DailyChart(summary: summary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const IslamicDivider(),
            const SizedBox(height: 16),

            // History section
            Text(
              'History',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Nothing saved yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < history.length; i++) ...[
                      _HistoryTile(
                        entry: history[i],
                        isBaseline: identical(history[i], store.entries.first),
                        onDelete: () => store.delete(history[i]),
                      ),
                      if (i < history.length - 1)
                        Divider(
                          height: 1,
                          indent: 56,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.daily, required this.summary, required this.now});

  final List<DailyCount> daily;

  /// The selected range; the average and total cover only this.
  final RangeSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final today = daily
        .where(
          (d) =>
              d.day.year == now.year &&
              d.day.month == now.month &&
              d.day.day == now.day,
        )
        .fold<int>(0, (sum, d) => sum + d.verses);

    return Row(
      children: [
        _StatTile(label: 'Today', value: '$today', icon: Icons.today_rounded),
        const SizedBox(width: 10),
        _StatTile(
          label: 'Daily Avg',
          value: summary.average.toStringAsFixed(0),
          icon: Icons.trending_up_rounded,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: 'Total',
          value: '${summary.total}',
          icon: Icons.auto_awesome_rounded,
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.daily, required this.now});

  final List<DailyCount> daily;
  final DateTime now;

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final streak = readingStreak(daily, now);
    final active = streak.current > 0;
    final flameColor = active
        ? (isDark ? AppColors.goldLight : AppColors.goldDark)
        : theme.colorScheme.outline;
    final readDays = {
      for (final d in daily)
        if (d.verses > 0) d.day,
    };
    final today = DateTime(now.year, now.month, now.day);
    final week = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];
    final fill = isDark ? AppColors.emeraldBright : AppColors.emerald;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: flameColor.withAlpha(30),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: flameColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streak.current == 1
                            ? '1 day streak'
                            : '${streak.current} day streak',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        streak.readToday
                            ? 'You read today. Keep it up!'
                            : active
                            ? 'Read today to keep your streak going'
                            : 'Read today to start a streak',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${streak.best}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Best',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final d in week)
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: readDays.contains(d)
                              ? fill
                              : theme.colorScheme.surfaceContainerHighest,
                          border: d == today
                              ? Border.all(color: flameColor, width: 2)
                              : null,
                        ),
                        child: readDays.contains(d)
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weekdayInitials[d.weekday - 1],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: d == today ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.gold),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.summary});

  final RangeSummary summary;

  static const _barSlot = 36.0;
  static const _leftReserved = 36.0;
  static const _bottomReserved = 40.0;
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _tooltip(ChartBucket b) => switch (summary.size) {
    BucketSize.day => '${formatDay(b.start)} · ${b.verses} verses',
    BucketSize.week =>
      'Week of ${formatDay(b.start)} · '
          '${b.perDay.round()} verses/day',
    BucketSize.month =>
      '${formatMonth(b.start)} · ${b.perDay.round()} verses/day',
  };

  /// Bar label on two short lines so it fits the bar slot; the full date is
  /// in the tooltip.
  (String, String) _label(DateTime d) => switch (summary.size) {
    BucketSize.day => ('${d.day}', _weekdays[d.weekday - 1]),
    BucketSize.week => ('${d.day}', formatMonthShort(d)),
    BucketSize.month => (
      formatMonthShort(d),
      "'${(d.year % 100).toString().padLeft(2, '0')}",
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buckets = summary.buckets;
    final values = [for (final b in buckets) b.perDay];
    final trend = linearTrend(values);
    final maxValue = values.fold<double>(0, math.max);
    final maxY = maxValue == 0 ? 10.0 : maxValue * 1.2;
    final barColor = isDark ? AppColors.emeraldBright : AppColors.emerald;
    final trendColor = isDark ? AppColors.goldLight : AppColors.goldDark;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    // The trend line is a LineChart laid over the bars with the same axis
    // space reserved. Bars are spaced evenly, so bar i is centred where the
    // line chart puts x = i when its x axis runs from -0.5 to n - 0.5.
    Widget? trendLine;
    if (trend != null) {
      final last = buckets.length - 1;
      trendLine = IgnorePointer(
        child: LineChart(
          LineChartData(
            minX: -0.5,
            maxX: buckets.length - 0.5,
            minY: 0,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: _leftReserved,
                  getTitlesWidget: (_, _) => const SizedBox.shrink(),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: _bottomReserved,
                  getTitlesWidget: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, trend.intercept),
                  FlSpot(last.toDouble(), trend.intercept + trend.slope * last),
                ],
                color: trendColor,
                barWidth: 2.5,
                dashArray: const [6, 4],
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      );
    }

    final chart = LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(
          constraints.maxWidth,
          buckets.length * _barSlot + _leftReserved,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: SizedBox(
            width: width,
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.colorScheme.outlineVariant,
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: _leftReserved,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: labelStyle,
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: _bottomReserved,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= buckets.length) {
                                return const SizedBox.shrink();
                              }
                              final (top, bottom) = _label(buckets[i].start);
                              final style = labelStyle?.copyWith(height: 1.2);
                              return SideTitleWidget(
                                meta: meta,
                                space: 6,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      top,
                                      style: style?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(bottom, style: style),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.emeraldDark,
                          getTooltipItem: (group, _, _, _) => BarTooltipItem(
                            _tooltip(buckets[group.x]),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < buckets.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: values[i],
                                width: 16,
                                color: barColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxY,
                                  color: barColor.withAlpha(12),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                if (trendLine != null) Positioned.fill(child: trendLine),
              ],
            ),
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chart,
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 4),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _LegendItem(
                color: barColor,
                label: switch (summary.size) {
                  BucketSize.day => 'Verses read',
                  BucketSize.week => 'Weekly average',
                  BucketSize.month => 'Monthly average',
                },
                labelStyle: labelStyle,
              ),
              if (trend != null)
                _LegendItem(
                  color: trendColor,
                  label: 'Trend',
                  labelStyle: labelStyle,
                  dashed: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.labelStyle,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final TextStyle? labelStyle;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dashed
            ? Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 4,
                      height: 2.5,
                      margin: const EdgeInsets.only(right: 2),
                      color: color,
                    ),
                ],
              )
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
        const SizedBox(width: 6),
        Text(label, style: labelStyle),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.isBaseline,
    required this.onDelete,
  });

  final ReadingEntry entry;
  final bool isBaseline;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ObjectKey(entry),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isBaseline ? Icons.flag_rounded : Icons.bookmark_rounded,
            color: isBaseline ? AppColors.gold : theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          '${surahs[entry.surah - 1].name} ${entry.surah}:${entry.verse}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          formatDateTime(entry.savedAt) +
              (isBaseline ? ' \u00b7 starting point' : ''),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
