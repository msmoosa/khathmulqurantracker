import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mushaf_layout.dart';
import '../data/quran.dart';
import '../data/quran_meta.dart';
import '../data/surahs.dart';
import '../state/reader_store.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../widgets/islamic_patterns.dart';

/// Reads the Quran page by page in the Uthmani script, laid out like the
/// printed Madani mushaf: the same 604 pages, each with the same 15 lines.
/// Pages turn right-to-left.
class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.initialPage,
    required this.reader,
    required this.tracker,
  });

  final int initialPage;
  final ReaderStore reader;
  final TrackerStore tracker;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late final PageController _pages;
  late int _page;
  final Future<QuranText> _text = QuranText.load();
  VerseRef? _selected;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, mushafPageCount);
    _pages = PageController(initialPage: _page - 1);
    // Saved after the first frame: this notifies listeners on the index
    // screen, which must not happen while the route is being built.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.reader.setLastPage(_page),
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _page = index + 1;
      _selected = null;
    });
    widget.reader.setLastPage(_page);
  }

  Future<void> _onVerseTap(QuranText text, VerseRef ref) async {
    setState(() => _selected = ref);
    final surah = surahs[ref.surah - 1];
    final messenger = ScaffoldMessenger.of(context);

    final action = await showModalBottomSheet<_VerseAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                '${surah.name} · Verse ${ref.verse}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_added_outlined),
              title: const Text('Mark as read up to here'),
              subtitle: Text('Saves ${surah.name} ${ref.verse} to the tracker'),
              onTap: () => Navigator.pop(context, _VerseAction.track),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy verse'),
              onTap: () => Navigator.pop(context, _VerseAction.copy),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (mounted) setState(() => _selected = null);
    switch (action) {
      case _VerseAction.track:
        await widget.tracker.save(ref.surah, ref.verse);
        messenger.showSnackBar(
          SnackBar(content: Text('Saved ${surah.name} ${ref.verse}')),
        );
      case _VerseAction.copy:
        await Clipboard.setData(
          ClipboardData(
            text:
                '${text.verse(ref.surah, ref.verse)}\n'
                '— Quran ${ref.surah}:${ref.verse} (${surah.name})',
          ),
        );
        messenger.showSnackBar(const SnackBar(content: Text('Verse copied')));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = pageStart(_page);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: const IslamicAppBarBackground(),
        title: Column(
          children: [
            Text(
              surahs[pageSurah(_page) - 1].name,
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                color: Colors.white,
              ),
            ),
            Text(
              'Juz ${juzOf(start.surah, start.verse)} · Page $_page',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.goldLight,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<QuranText>(
          future: _text,
          initialData: QuranText.loaded,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Could not load the Quran text.'),
              );
            }
            final text = snapshot.data;
            if (text == null) {
              return const Center(child: CircularProgressIndicator());
            }
            // Let a mouse drag turn pages too (web and desktop).
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(dragDevices: {...PointerDeviceKind.values}),
              child: PageView.builder(
                controller: _pages,
                // A mushaf opens from the right, so the next page is on
                // the left.
                reverse: true,
                itemCount: mushafPageCount,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) => _BookPage(
                  page: i + 1,
                  text: text,
                  selected: _selected,
                  onVerseTap: (ref) => _onVerseTap(text, ref),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _VerseAction { track, copy }

/// Lines per page of the Madani mushaf.
const _linesPerPage = 15;

/// Line height as a multiple of the font size; the Uthmani script needs
/// room above and below for its marks.
const _lineHeightFactor = 1.9;

/// Below this font size a page no longer fits the screen legibly (e.g. in
/// landscape), so it is sized to the width and scrolls instead.
const _minFittedFontSize = 15.0;

/// Smallest gap between words, as a multiple of the font size.
const _gapFactor = 0.18;

/// One page of the mushaf, line for line as printed.
class _BookPage extends StatelessWidget {
  const _BookPage({
    required this.page,
    required this.text,
    required this.selected,
    required this.onVerseTap,
  });

  final int page;
  final QuranText text;
  final VerseRef? selected;
  final ValueChanged<VerseRef> onVerseTap;

  /// Index of the first token after the text lines of this page.
  int get _pageEnd {
    if (page == mushafPageCount) return text.tokens.length;
    return mushafLines[page].firstWhere((l) => l >= 0);
  }

  /// The tokens of each line, or null for a banner or Bismillah line.
  List<List<MushafToken>?> get _lineTokens {
    final lines = mushafLines[page - 1];
    final result = <List<MushafToken>?>[];
    for (var i = 0; i < lines.length; i++) {
      if (lines[i] < 0) {
        result.add(null);
        continue;
      }
      final next = lines
          .skip(i + 1)
          .firstWhere((l) => l >= 0, orElse: () => _pageEnd);
      result.add(text.tokens.sublist(lines[i], next));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final start = pageStart(page);
    final runningStyle = TextStyle(
      fontFamily: quranFontFamily,
      fontSize: 15,
      height: 1.6,
      color: muted,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Running header, as at the top of a printed page.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة ${surahArabicNames[pageSurah(page) - 1]}',
                  style: runningStyle,
                ),
                Text(
                  'الجزء ${arabicNumber(juzOf(start.surah, start.verse))}',
                  style: runningStyle,
                ),
              ],
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.gold.withAlpha(150),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        _buildLines(context, constraints),
                  ),
                ),
              ),
            ),
            Text(
              arabicNumber(page),
              textAlign: TextAlign.center,
              style: runningStyle.copyWith(fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLines(BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = constraints.maxWidth;
    final lineTokens = _lineTokens;

    // Size the text so the widest line fits the width and all 15 lines fit
    // the height, then justify every line to the full width like print.
    const baseSize = 20.0;
    final base = TextStyle(fontFamily: quranFontFamily, fontSize: baseSize);
    final natural = [
      for (final tokens in lineTokens)
        tokens == null ? 0.0 : _lineWidth(tokens, base),
    ];
    final widest = natural.fold(0.0, math.max);
    final widthFit = widest == 0 ? 28.0 : baseSize * width * 0.99 / widest;
    final heightFit = constraints.maxHeight / _linesPerPage / _lineHeightFactor;
    final scrolls = heightFit < _minFittedFontSize;
    final fontSize = scrolls
        ? math.min(widthFit, 30.0)
        : math.min(widthFit, heightFit);
    // Spread the lines over the whole page, as in print.
    final lineHeight = scrolls
        ? fontSize * _lineHeightFactor
        : math.max(
            fontSize * _lineHeightFactor,
            constraints.maxHeight / _linesPerPage,
          );

    final wordStyle = TextStyle(
      fontFamily: quranFontFamily,
      fontSize: fontSize,
      height: 1,
      color: theme.colorScheme.onSurface,
    );
    final markerStyle = wordStyle.copyWith(
      color: isDark ? AppColors.gold : AppColors.emeraldLight,
    );
    final highlight = AppColors.gold.withAlpha(isDark ? 70 : 60);

    Widget token(MushafToken t) {
      final isSelected = selected == t.ref;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onVerseTap(t.ref),
        child: Container(
          height: lineHeight,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: fontSize * _gapFactor / 2),
          decoration: isSelected
              ? BoxDecoration(
                  color: highlight,
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Text(
            t.text,
            textScaler: TextScaler.noScaling,
            style: t.isVerseEnd ? markerStyle : wordStyle,
          ),
        ),
      );
    }

    final lines = mushafLines[page - 1];
    final rows = <Widget>[];
    for (var i = 0; i < lines.length; i++) {
      final tokens = lineTokens[i];
      Widget row;
      if (lines[i] == bismillahLine) {
        row = Center(
          child: Text(
            text.bismillah,
            textScaler: TextScaler.noScaling,
            style: wordStyle,
          ),
        );
      } else if (tokens == null) {
        row = _SurahHeader(surah: -lines[i], height: lineHeight * 0.92);
      } else {
        // Short lines (the opening pages, or where a surah ends) are
        // centred rather than stretched.
        final short =
            page <= 2 || natural[i] * fontSize / baseSize < width * 0.75;
        // Scaled down rather than clipped if a line ever measures wider
        // than expected (e.g. a fallback font).
        row = FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: short ? 0 : width),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (k, t) in tokens.indexed) ...[
                  if (short && k > 0) SizedBox(width: fontSize * 0.2),
                  token(t),
                ],
              ],
            ),
          ),
        );
      }
      rows.add(SizedBox(height: lineHeight, child: row));
    }

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
    if (scrolls) return SingleChildScrollView(child: column);
    return Center(child: column);
  }

  /// Width of a line's words set side by side with a small gap, which is
  /// the tightest the justified row can be.
  static double _lineWidth(List<MushafToken> tokens, TextStyle style) =>
      tokens.fold(
        _gapFactor * style.fontSize! * tokens.length,
        (sum, t) => sum + _measure(t.text, style),
      );

  static double _measure(String s, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }
}

/// Ornamental banner that opens a surah.
class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah, required this.height});

  final int surah;
  final double height;

  @override
  Widget build(BuildContext context) {
    final info = surahs[surah - 1];
    final small = TextStyle(
      fontFamily: quranFontFamily,
      fontSize: height * 0.24,
      color: AppColors.goldLight,
    );

    return Center(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height * 0.2),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height * 0.17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const IslamicAppBarBackground(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        surahIsMeccan[surah - 1] ? 'مكية' : 'مدنية',
                        textScaler: TextScaler.noScaling,
                        style: small,
                      ),
                    ),
                    Text(
                      'سورة ${surahArabicNames[surah - 1]}',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontFamily: quranFontFamily,
                        fontSize: height * 0.42,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'آياتها ${arabicNumber(info.verseCount)}',
                        textAlign: TextAlign.left,
                        textScaler: TextScaler.noScaling,
                        style: small,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
