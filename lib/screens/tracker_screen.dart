import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../util/format.dart';
import '../widgets/islamic_patterns.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key, required this.store});

  final TrackerStore store;

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  static const _itemExtent = 64.0;

  late int _surah;
  late int _verse;
  late final FixedExtentScrollController _surahCtrl;
  late final FixedExtentScrollController _verseCtrl;
  late final TextEditingController _verseTextCtrl;
  final _verseFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final last = widget.store.lastEntry;
    _surah = last?.surah ?? 1;
    _verse = last?.verse ?? 1;
    _surahCtrl = FixedExtentScrollController(initialItem: _surah - 1);
    _verseCtrl = FixedExtentScrollController(initialItem: _verse - 1);
    _verseTextCtrl = TextEditingController(text: '$_verse');
    widget.store.addListener(_onStoreChanged);
  }

  void _onStoreChanged() => setState(() {});

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _surahCtrl.dispose();
    _verseCtrl.dispose();
    _verseTextCtrl.dispose();
    _verseFocus.dispose();
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
    _verseTextCtrl.text = '$_verse';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verseCtrl.hasClients && _verseCtrl.selectedItem != _verse - 1) {
        _verseCtrl.jumpToItem(_verse - 1);
      }
    });
  }

  void _onVerseSubmitted(String text) {
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 1 || parsed > _current.verseCount) {
      _verseTextCtrl.text = '$_verse';
      return;
    }
    setState(() => _verse = parsed);
    _verseCtrl.jumpToItem(parsed - 1);
    _verseFocus.unfocus();
  }

  Future<void> _save() async {
    await widget.store.save(_surah, _verse);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Saved ${_current.name} $_surah:$_verse'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _reset() {
    final last = widget.store.lastEntry;
    final surah = last?.surah ?? 1;
    final verse = last?.verse ?? 1;
    setState(() {
      _surah = surah;
      _verse = verse;
    });
    _verseTextCtrl.text = '$verse';
    _surahCtrl.jumpToItem(surah - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verseCtrl.hasClients) _verseCtrl.jumpToItem(verse - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = widget.store.lastEntry;
    final progress = absoluteVerse(_surah, _verse) / totalVerses;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Islamic pattern
          IslamicHeader(
            title: 'Khathmul Quran Tracker',
            subtitle: last == null
                ? 'No position saved yet'
                : 'Last: ${surahs[last.surah - 1].name} '
                      '${last.surah}:${last.verse} \u00b7 ${formatDateTime(last.savedAt)}',
            child: _ProgressIndicator(
              progress: progress,
              surahName: _current.name,
              surah: _surah,
              verse: _verse,
              verseCount: _current.verseCount,
            ),
          ),

          const SizedBox(height: 20),

          // Surah label
          Text(
            'Surah',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Surah picker — shows ~3 items
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: CupertinoPicker.builder(
                  scrollController: _surahCtrl,
                  itemExtent: _itemExtent,
                  onSelectedItemChanged: _onSurahChanged,
                  selectionOverlay: _selectionOverlay(context),
                  childCount: surahs.length,
                  itemBuilder: (context, i) => Center(
                    child: Text(
                      '${surahs[i].number}. ${surahs[i].name}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Verse input — editable text field with scroll buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Verse',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _VerseButton(
                    icon: Icons.remove_rounded,
                    onPressed: _verse > 1
                        ? () {
                            setState(() => _verse--);
                            _verseTextCtrl.text = '$_verse';
                            _verseCtrl.jumpToItem(_verse - 1);
                          }
                        : null,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _verseTextCtrl,
                      focusNode: _verseFocus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        suffixText: '/ ${_current.verseCount}',
                        suffixStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onSubmitted: _onVerseSubmitted,
                      onTapOutside: (_) {
                        _onVerseSubmitted(_verseTextCtrl.text);
                        _verseFocus.unfocus();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _VerseButton(
                    icon: Icons.add_rounded,
                    onPressed: _verse < _current.verseCount
                        ? () {
                            setState(() => _verse++);
                            _verseTextCtrl.text = '$_verse';
                            _verseCtrl.jumpToItem(_verse - 1);
                          }
                        : null,
                    theme: theme,
                  ),
                ],
              ),
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

class _VerseButton extends StatelessWidget {
  const _VerseButton({
    required this.icon,
    required this.onPressed,
    required this.theme,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primary.withAlpha(20),
          foregroundColor: theme.colorScheme.primary,
          disabledBackgroundColor: theme.colorScheme.outlineVariant.withAlpha(
            40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.progress,
    required this.surahName,
    required this.surah,
    required this.verse,
    required this.verseCount,
  });

  final double progress;
  final String surahName;
  final int surah;
  final int verse;
  final int verseCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '$surahName \u00b7 Verse $verse of $verseCount',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withAlpha(200),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withAlpha(80)),
              ),
              child: Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withAlpha(30),
            valueColor: const AlwaysStoppedAnimation(AppColors.goldLight),
          ),
        ),
      ],
    );
  }
}
