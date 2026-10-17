import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../models/reading_entry.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../util/format.dart';
import '../widgets/islamic_patterns.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.store});

  final TrackerStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final theme = Theme.of(context);
        final daily = store.daily;
        final history = store.entries.reversed.toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            IslamicHeader(
              title: 'Progress',
              subtitle: daily.isEmpty
                  ? 'Start tracking to see your journey'
                  : '${daily.length} day${daily.length == 1 ? '' : 's'} of reading',
            ),
            const SizedBox(height: 20),

            // Stats row
            _Stats(daily: daily),
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
                        'Daily Verses',
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
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
                        : _DailyChart(daily: daily),
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
                        isBaseline:
                            identical(history[i], store.entries.first),
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
  const _Stats({required this.daily});

  final List<DailyCount> daily;

  @override
  Widget build(BuildContext context) {
    final total = daily.fold<int>(0, (sum, d) => sum + d.verses);
    final avg = daily.isEmpty ? 0 : total / daily.length;
    final now = DateTime.now();
    final today = daily
        .where((d) =>
            d.day.year == now.year &&
            d.day.month == now.month &&
            d.day.day == now.day)
        .fold<int>(0, (sum, d) => sum + d.verses);

    return Row(
      children: [
        _StatTile(label: 'Today', value: '$today', icon: Icons.today_rounded),
        const SizedBox(width: 10),
        _StatTile(
            label: 'Daily Avg',
            value: avg.toStringAsFixed(0),
            icon: Icons.trending_up_rounded),
        const SizedBox(width: 10),
        _StatTile(
            label: 'Total', value: '$total', icon: Icons.auto_awesome_rounded),
      ],
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
              Icon(
                icon,
                size: 20,
                color: AppColors.gold,
              ),
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
  const _DailyChart({required this.daily});

  final List<DailyCount> daily;

  static const _barSlot = 36.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxVerses = daily.map((d) => d.verses).fold<int>(0, math.max);
    final maxY = maxVerses == 0 ? 10.0 : maxVerses * 1.2;
    final barColor = isDark ? AppColors.emeraldLight : AppColors.emerald;

    return LayoutBuilder(builder: (context, constraints) {
      final width = math.max(constraints.maxWidth, daily.length * _barSlot);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: SizedBox(
          width: width,
          height: 220,
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
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= daily.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          formatDay(daily[i].day),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.emeraldDark,
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${rod.toY.toInt()} verses',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < daily.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: daily[i].verses.toDouble(),
                      width: 16,
                      color: barColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: barColor.withAlpha(12),
                      ),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      );
    });
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
        child: Icon(Icons.delete_rounded,
            color: theme.colorScheme.onErrorContainer),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isBaseline
                ? Icons.flag_rounded
                : Icons.bookmark_rounded,
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
