import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/quran_meta.dart';
import '../data/surahs.dart';
import '../state/reader_store.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../widgets/islamic_patterns.dart';
import 'quran_reader_screen.dart';

enum _IndexMode { surah, juz }

/// Index of surahs and juz that opens the mushaf reader.
class QuranIndexScreen extends StatefulWidget {
  const QuranIndexScreen({
    super.key,
    required this.reader,
    required this.tracker,
  });

  final ReaderStore reader;
  final TrackerStore tracker;

  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends State<QuranIndexScreen> {
  final _search = TextEditingController();
  var _mode = _IndexMode.surah;
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(int page) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderScreen(
          initialPage: page,
          reader: widget.reader,
          tracker: widget.tracker,
        ),
      ),
    );
  }

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r"[\s'\-’]"), '');

  List<Surah> get _filtered {
    final q = _normalize(_query);
    if (q.isEmpty) return surahs;
    return surahs.where((s) {
      return s.number.toString() == q ||
          _normalize(s.name).contains(q) ||
          surahArabicNames[s.number - 1].contains(_query.trim());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListenableBuilder(
                listenable: widget.reader,
                builder: (context, _) {
                  final page = widget.reader.lastPage;
                  if (page == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ContinueCard(page: page, onTap: () => _open(page)),
                  );
                },
              ),
              SegmentedButton<_IndexMode>(
                segments: const [
                  ButtonSegment(value: _IndexMode.surah, label: Text('Surah')),
                  ButtonSegment(value: _IndexMode.juz, label: Text('Juz')),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              if (_mode == _IndexMode.surah) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search surah by name or number',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _mode == _IndexMode.surah
              ? _SurahList(surahs: _filtered, onOpen: _open)
              : _JuzList(onOpen: _open),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.page, required this.onTap});

  final int page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = pageStart(page);
    final surah = surahs[pageSurah(page) - 1];

    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            const Positioned.fill(child: IslamicAppBarBackground()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue reading',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.goldLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${surah.name} · Page $page · '
                          'Juz ${juzOf(start.surah, start.verse)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({required this.surahs, required this.onOpen});

  final List<Surah> surahs;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (surahs.isEmpty) {
      return Center(
        child: Text(
          'No surah matches your search',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: surahs.length,
      separatorBuilder: (_, _) => Divider(
        height: 0.5,
        indent: 72,
        endIndent: 16,
        color: theme.colorScheme.outlineVariant,
      ),
      itemBuilder: (context, i) {
        final s = surahs[i];
        final page = pageOf(s.number, 1);
        final place = surahIsMeccan[s.number - 1] ? 'Meccan' : 'Medinan';
        return _IndexTile(
          number: s.number,
          title: s.name,
          subtitle: '$place · ${s.verseCount} verses · Page $page',
          arabic: surahArabicNames[s.number - 1],
          onTap: () => onOpen(page),
        );
      },
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList({required this.onOpen});

  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      itemCount: 30,
      separatorBuilder: (_, _) => Divider(
        height: 0.5,
        indent: 72,
        endIndent: 16,
        color: theme.colorScheme.outlineVariant,
      ),
      itemBuilder: (context, i) {
        final juz = i + 1;
        final start = juzStart(juz);
        final page = pageOf(start.surah, start.verse);
        return _IndexTile(
          number: juz,
          title: 'Juz $juz',
          subtitle:
              'Starts at ${surahs[start.surah - 1].name} ${start.verse} · '
              'Page $page',
          arabic: 'الجزء ${arabicNumber(juz)}',
          onTap: () => onOpen(page),
        );
      },
    );
  }
}

class _IndexTile extends StatelessWidget {
  const _IndexTile({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.arabic,
    required this.onTap,
  });

  final int number;
  final String title;
  final String subtitle;
  final String arabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: _StarBadge(number: number),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        arabic,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: quranFontFamily,
          fontSize: 22,
          height: 1.4,
          color: theme.colorScheme.primary,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// A number inside an eight-pointed star, like the markers in a mushaf.
class _StarBadge extends StatelessWidget {
  const _StarBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? AppColors.gold : AppColors.goldDark;
    // Opaque so the two overlapping squares read as a single star.
    final fill = Color.alphaBlend(
      theme.colorScheme.primaryContainer,
      theme.colorScheme.surface,
    );
    Widget square(double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border, width: 1.2),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          square(0),
          square(math.pi / 4),
          Text(
            '$number',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.goldLight : AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}
