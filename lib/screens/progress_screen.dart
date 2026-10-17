import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../models/reading_entry.dart';
import '../state/tracker_store.dart';
import '../util/format.dart';

/// Charts verses read per day and lists the saved history.
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
            Text('Progress', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            _Stats(daily: daily),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: daily.isEmpty
                    ? const SizedBox(
                        height: 200,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Save your position on at least two occasions '
                              'to see daily verses read. The first save is '
                              'only used as a starting point.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    : _DailyChart(daily: daily),
              ),
            ),
            const SizedBox(height: 24),
            Text('History', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Text('Nothing saved yet.')
            else
              for (final entry in history)
                _HistoryTile(
                  entry: entry,
                  isBaseline: identical(entry, store.entries.first),
                  onDelete: () => store.delete(entry),
                ),
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
        _StatTile(label: 'Today', value: '$today'),
        const SizedBox(width: 8),
        _StatTile(label: 'Daily avg', value: avg.toStringAsFixed(0)),
        const SizedBox(width: 8),
        _StatTile(label: 'Total', value: '$total'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(value, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
    final maxVerses = daily.map((d) => d.verses).fold<int>(0, math.max);
    final maxY = maxVerses == 0 ? 10.0 : maxVerses * 1.2;

    return LayoutBuilder(builder: (context, constraints) {
      final width = math.max(constraints.maxWidth, daily.length * _barSlot);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Start scrolled to the most recent day.
        reverse: true,
        child: SizedBox(
          width: width,
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 36),
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
                        child: Text(formatDay(daily[i].day),
                            style: theme.textTheme.labelSmall),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${rod.toY.toInt()} verses',
                    TextStyle(color: theme.colorScheme.onInverseSurface),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < daily.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: daily[i].verses.toDouble(),
                      width: 18,
                      color: theme.colorScheme.primary,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.bookmark_outline),
        title: Text(
            '${surahs[entry.surah - 1].name} ${entry.surah}:${entry.verse}'),
        subtitle: Text(formatDateTime(entry.savedAt) +
            (isBaseline ? ' · starting point' : '')),
      ),
    );
  }
}
