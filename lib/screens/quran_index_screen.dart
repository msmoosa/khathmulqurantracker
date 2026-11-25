import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/daily_surahs.dart';
import '../data/quran.dart';
import '../data/quran_meta.dart';
import '../data/surahs.dart';
import '../state/appearance_store.dart';
import '../state/reader_store.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../widgets/islamic_patterns.dart';
import '../widgets/no_bold_text.dart';
import 'quran_reader_screen.dart';

enum _IndexMode { surah, juz }

/// Index of surahs and juz that opens the mushaf reader.
class QuranIndexScreen extends StatefulWidget {
  const QuranIndexScreen({
    super.key,
    required this.reader,
    required this.tracker,
    required this.appearance,
  });

  final ReaderStore reader;
  final TrackerStore tracker;
  final AppearanceStore appearance;

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

  void _open(int page, {VerseRef? highlight}) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderScreen(
          initialPage: page,
          highlight: highlight,
          reader: widget.reader,
          tracker: widget.tracker,
          appearance: widget.appearance,
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
                listenable: Listenable.merge([widget.reader, widget.tracker]),
                builder: (context, _) {
                  // Picks up where the tracker is up to, marking the verse;
                  // before anything is tracked, the last page read.
                  final last = widget.tracker.lastEntry;
                  final verse = last == null
                      ? null
                      : VerseRef(last.surah, last.verse);
                  final page = verse == null
                      ? widget.reader.lastPage
                      : pageOf(verse.surah, verse.verse);
                  if (page == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ContinueCard(
                      page: page,
                      verse: verse,
                      onTap: () => _open(page, highlight: verse),
                    ),
                  );
                },
              ),
              ListenableBuilder(
                listenable: widget.reader,
                builder: (context, _) => _DailySurahs(
                  marks: widget.reader.surahMarks,
                  onOpen: (d) {
                    final mark = d.verse
                        ? null
                        : widget.reader.surahMark(d.start.surah);
                    final at = mark ?? d.start.verse;
                    _open(pageOf(d.start.surah, at));
                  },
                ),
              ),
              const SizedBox(height: 10),
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
              ? ListenableBuilder(
                  listenable: widget.reader,
                  builder: (context, _) => _SurahList(
                    surahs: _filtered,
                    marks: widget.reader.surahMarks,
                    onOpen: _open,
                  ),
                )
              : _JuzList(onOpen: _open),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.page, this.verse, required this.onTap});

  final int page;
  final VerseRef? verse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = pageStart(page);
    final verse = this.verse;
    final surah = surahs[(verse?.surah ?? pageSurah(page)) - 1];

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
                          verse == null
                              ? '${surah.name} · Page $page · '
                                    'Juz ${juzOf(start.surah, start.verse)}'
                              : '${surah.name} ${verse.surah}:${verse.verse}'
                                    ' · Page $page',
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

/// A line of surahs commonly read every day. A tap opens one (at its
/// surah mark, if it has one) and a hold shows the hadith about it.
class _DailySurahs extends StatelessWidget {
  const _DailySurahs({required this.marks, required this.onOpen});

  final Map<int, int> marks;
  final ValueChanged<DailySurah> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Often read',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          for (final d in dailySurahs)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: theme.colorScheme.surfaceContainerLowest,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isDark ? AppColors.goldDark : AppColors.gold,
                    width: 0.8,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onOpen(d),
                  onLongPress: () => _showVirtues(context, d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!d.verse && marks.containsKey(d.start.surah)) ...[
                          Icon(
                            Icons.bookmark_rounded,
                            size: 14,
                            color: surahMarkColor(context),
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          d.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showVirtues(BuildContext context, DailySurah d) {
    showDialog<void>(
      context: context,
      builder: (context) => _VirtuesDialog(
        surah: d,
        onOpen: () {
          Navigator.pop(context);
          onOpen(d);
        },
      ),
    );
  }
}

/// The hadith about reciting a daily surah, each marked strong or weak.
class _VirtuesDialog extends StatelessWidget {
  const _VirtuesDialog({required this.surah, required this.onOpen});

  final DailySurah surah;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return AlertDialog(
      title: Text(surah.label),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, v) in surah.virtues.indexed) ...[
              if (i > 0) const Divider(height: 24),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _StrengthChip(strength: v.strength),
              ),
              const SizedBox(height: 8),
              Text(
                '"${v.meaning}"',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                'Narrated by ${v.narrator} · ${v.source}',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              Text(
                'Grading: ${v.grade}',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Weak hadith are shown so you know of them; scholars do not '
              'rely on them to establish a virtue.',
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(onPressed: onOpen, child: const Text('Read')),
      ],
    );
  }
}

class _StrengthChip extends StatelessWidget {
  const _StrengthChip({required this.strength});

  final HadithStrength strength;

  @override
  Widget build(BuildContext context) {
    final strong = strength == HadithStrength.strong;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = strong
        ? (isDark ? AppColors.emeraldBright : AppColors.emerald)
        : (isDark ? const Color(0xFFE0A050) : const Color(0xFFA85A12));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            strong ? Icons.verified_rounded : Icons.error_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            strong ? 'Strong hadith' : 'Weak hadith',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({
    required this.surahs,
    required this.marks,
    required this.onOpen,
  });

  final List<Surah> surahs;

  /// [ReaderStore.surahMarks]: a marked surah opens at its mark.
  final Map<int, int> marks;
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
        final mark = marks[s.number];
        return _IndexTile(
          number: s.number,
          title: s.name,
          subtitle: '$place · ${s.verseCount} verses · Page $page',
          mark: mark,
          arabic: surahArabicNames[s.number - 1],
          onTap: () => onOpen(mark == null ? page : pageOf(s.number, mark)),
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
    this.mark,
  });

  final int number;
  final String title;
  final String subtitle;

  /// The verse of the surah's mark, if it has one.
  final int? mark;
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
      subtitle: Text.rich(
        TextSpan(
          children: [
            if (mark != null) ...[
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  Icons.bookmark_rounded,
                  size: 14,
                  color: surahMarkColor(context),
                ),
              ),
              TextSpan(
                text: 'Verse $mark · ',
                style: TextStyle(
                  color: surahMarkColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            TextSpan(text: subtitle),
          ],
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: NoBoldText(
        child: Text(
          arabic,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: quranFontFamily,
            fontSize: 22,
            height: 1.4,
            color: theme.colorScheme.primary,
          ),
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
