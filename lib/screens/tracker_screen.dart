import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/surahs.dart';
import '../models/reading_entry.dart';
import '../models/streak.dart';
import '../state/reader_store.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../widgets/top_toast.dart';
import 'quran_reader_screen.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key, required this.store, required this.reader});

  final TrackerStore store;
  final ReaderStore reader;

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  static const _itemExtent = 52.0;

  late int _surah;
  late int _verse;
  late final FixedExtentScrollController _surahCtrl;
  late final FixedExtentScrollController _verseCtrl;

  /// The latest saved entry the pickers have been synced to.
  ReadingEntry? _synced;

  @override
  void initState() {
    super.initState();
    final last = widget.store.lastEntry;
    _synced = last;
    _surah = last?.surah ?? 1;
    _verse = last?.verse ?? 1;
    _surahCtrl = FixedExtentScrollController(initialItem: _surah - 1);
    _verseCtrl = FixedExtentScrollController(initialItem: _verse - 1);
    widget.store.addListener(_onStoreChanged);
  }

  /// Moves the pickers to a position saved elsewhere, such as "Mark as read
  /// up to here" in the reader.
  void _onStoreChanged() {
    final last = widget.store.lastEntry;
    if (last != null && !identical(last, _synced)) {
      _synced = last;
      _reset();
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _surahCtrl.dispose();
    _verseCtrl.dispose();
    super.dispose();
  }

  Surah get _current => surahs[_surah - 1];

  bool get _isDirty {
    final last = widget.store.lastEntry;
    if (last == null) return true;
    return last.surah != _surah || last.verse != _verse;
  }

  void _onSurahChanged(int index) {
    final count = surahs[index].verseCount;
    setState(() {
      _surah = index + 1;
      if (_verse > count) _verse = count;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verseCtrl.hasClients && _verseCtrl.selectedItem != _verse - 1) {
        _verseCtrl.jumpToItem(_verse - 1);
      }
    });
  }

  Future<void> _save() async {
    await widget.store.save(_surah, _verse);
    if (!mounted) return;
    final saved = 'Saved ${_current.name} $_surah:$_verse';
    final streak = readingStreak(widget.store.daily, DateTime.now()).current;
    if (streak == 0) {
      showTopToast(context, saved);
    } else {
      showTopToast(
        context,
        streak == 1 ? '$saved · Streak started' : '$saved · $streak-day streak',
        icon: Icons.local_fire_department_rounded,
        // The toast is dark in light mode and light in dark mode.
        iconColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.goldDark
            : AppColors.goldLight,
      );
    }
  }

  void _reset() {
    final last = widget.store.lastEntry;
    final surah = last?.surah ?? 1;
    final verse = last?.verse ?? 1;
    setState(() {
      _surah = surah;
      _verse = verse;
    });
    _surahCtrl.jumpToItem(surah - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verseCtrl.hasClients) _verseCtrl.jumpToItem(verse - 1);
    });
  }

  /// Opens the reader on the page of the selected verse, with it highlighted.
  void _jumpToVerse() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderScreen(
          initialPage: pageOf(_surah, _verse),
          highlight: VerseRef(_surah, _verse),
          reader: widget.reader,
          tracker: widget.store,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = widget.store.lastEntry;
    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
    final itemStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Labels and pickers, capped at 30% of the screen height and
          // centred in the space above the buttons.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = math.min(
                  constraints.maxHeight,
                  MediaQuery.sizeOf(context).height * 0.3,
                );
                return Center(
                  child: SizedBox(
                    height: height,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Labels
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Surah',
                                textAlign: TextAlign.center,
                                style: labelStyle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Verse / ${_current.verseCount}',
                                textAlign: TextAlign.center,
                                style: labelStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Surah and verse pickers side by side
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _PickerCard(
                                  child: CupertinoPicker.builder(
                                    scrollController: _surahCtrl,
                                    itemExtent: _itemExtent,
                                    onSelectedItemChanged: _onSurahChanged,
                                    selectionOverlay: _selectionOverlay(
                                      context,
                                    ),
                                    childCount: surahs.length,
                                    itemBuilder: (context, i) => Center(
                                      child: Text(
                                        '${surahs[i].number}. ${surahs[i].name}',
                                        style: itemStyle,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _PickerCard(
                                  child: CupertinoPicker.builder(
                                    scrollController: _verseCtrl,
                                    itemExtent: _itemExtent,
                                    onSelectedItemChanged: (i) =>
                                        setState(() => _verse = i + 1),
                                    selectionOverlay: _selectionOverlay(
                                      context,
                                    ),
                                    childCount: _current.verseCount,
                                    itemBuilder: (context, i) => Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: itemStyle?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isDirty && last != null ? _reset : null,
                  icon: const Icon(Icons.undo_rounded, size: 20),
                  label: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isDirty ? _save : null,
                  icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _jumpToVerse,
              icon: const Icon(Icons.auto_stories_rounded, size: 20),
              label: Text('Jump to $_surah:$_verse in the Quran'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionOverlay(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: primary.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          top: BorderSide(color: primary.withAlpha(40), width: 0.5),
          bottom: BorderSide(color: primary.withAlpha(40), width: 0.5),
        ),
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: child,
      ),
    );
  }
}
