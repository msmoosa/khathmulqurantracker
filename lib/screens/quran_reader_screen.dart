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

  /// Whether the top bar is showing. It starts visible so the way back is
  /// obvious, hides on the first page turn, and a tap toggles it.
  var _showBar = true;

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
      _showBar = false;
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
    final isDark = theme.brightness == Brightness.dark;

    final page = FutureBuilder<QuranText>(
      future: _text,
      initialData: QuranText.loaded,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load the Quran text.'));
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
            // A mushaf opens from the right, so the next page is on the left.
            reverse: true,
            itemCount: mushafPageCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) => _BookPage(
              page: i + 1,
              text: text,
              selected: _selected,
              onVerseLongPress: (ref) => _onVerseTap(text, ref),
            ),
          ),
        );
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.paper,
        body: Stack(
          children: [
            SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showBar = !_showBar),
                child: page,
              ),
            ),
            AnimatedSlide(
              offset: _showBar ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: SizedBox(
                height: kToolbarHeight + MediaQuery.paddingOf(context).top,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                  flexibleSpace: const IslamicAppBarBackground(),
                  title: Text(
                    'Page $_page',
                    style: theme.appBarTheme.titleTextStyle?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        child: Text(
                          'Hold a verse for options',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.goldLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    required this.onVerseLongPress,
  });

  final int page;
  final QuranText text;
  final VerseRef? selected;
  final ValueChanged<VerseRef> onVerseLongPress;

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
    final start = pageStart(page);
    final surah = surahs[pageSurah(page) - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page caption, as in the margin of a printed mushaf.
          Text(
            '${surah.name}, Juz ${juzOf(start.surah, start.verse)}, '
            'Hizb ${hizbLabel(start.surah, start.verse)}, Page $page',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _buildLines(context, constraints),
              ),
            ),
          ),
        ],
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
    // Natural width of every token, with its share of the minimum gap.
    final tokenWidths = [
      for (final tokens in lineTokens)
        tokens == null
            ? const <double>[]
            : [
                for (final t in tokens)
                  _measure(t.text, base) + _gapFactor * baseSize,
              ],
    ];
    final natural = [
      for (final widths in tokenWidths) widths.fold(0.0, (a, b) => a + b),
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

    final ink = isDark ? AppColors.paper : AppColors.ink;
    final wordStyle = TextStyle(
      fontFamily: quranFontFamily,
      fontSize: fontSize,
      height: 1,
      color: ink,
    );
    final highlight = AppColors.gold.withAlpha(isDark ? 80 : 70);

    Widget token(MushafToken t) {
      final isSelected = selected == t.ref;
      return GestureDetector(
        // Opaque so the whole cell, not just the glyphs, can be held.
        behavior: HitTestBehavior.opaque,
        onLongPress: () => onVerseLongPress(t.ref),
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
            softWrap: false,
            overflow: TextOverflow.visible,
            style: wordStyle,
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
        row = _SurahHeader(
          surah: -lines[i],
          height: lineHeight * 0.95,
          color: ink,
        );
      } else {
        // Short lines (the opening pages, or where a surah ends) are
        // centred rather than stretched.
        final short =
            page <= 2 || natural[i] * fontSize / baseSize < width * 0.75;
        row = short
            // Scaled down rather than clipped if a line ever measures
            // wider than expected (e.g. a fallback font).
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    for (final (k, t) in tokens.indexed) ...[
                      if (k > 0) SizedBox(width: fontSize * 0.2),
                      token(t),
                    ],
                  ],
                ),
              )
            // Justify by giving each word a share of the spare width in
            // proportion to its size, so the whole line can be held.
            : Row(
                children: [
                  for (final (k, t) in tokens.indexed)
                    Expanded(
                      flex: math.max(1, (tokenWidths[i][k] * 10).round()),
                      child: token(t),
                    ),
                ],
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
    return Align(alignment: Alignment.topCenter, child: column);
  }

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

/// The engraved frame that opens a surah: a double-ruled panel with
/// knotwork ends, roundels, and a cartouche holding the surah's name.
class _SurahHeader extends StatelessWidget {
  const _SurahHeader({
    required this.surah,
    required this.height,
    required this.color,
  });

  final int surah;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _SurahFramePainter(color),
          child: Center(
            child: Text(
              'سُورَةُ ${surahArabicNames[surah - 1]}',
              textDirection: TextDirection.rtl,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: quranFontFamily,
                fontSize: height * 0.36,
                height: 1.1,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahFramePainter extends CustomPainter {
  _SurahFramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final thick = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, h * 0.045);
    final thin = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, h * 0.018);

    // Double rule around the panel.
    final outer = Rect.fromLTWH(0, 0, w, h).deflate(thick.strokeWidth / 2);
    canvas.drawRect(outer, thick);
    final inner = outer.deflate(h * 0.08);
    canvas.drawRect(inner, thin);

    // Central cartouche for the name.
    final cy = h / 2;
    final ch = inner.height * 0.82;
    final cw = w * 0.42;
    final cartouche = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, cy), width: cw, height: ch),
      Radius.circular(ch / 2),
    );
    canvas.drawRRect(cartouche, thin);
    canvas.drawRRect(cartouche.deflate(h * 0.06), thin);

    // Roundels on either side of the cartouche.
    final r = ch * 0.38;
    final roundelGap = (w / 2 - cw / 2) * 0.32;
    for (final dx in [-1.0, 1.0]) {
      final c = Offset(w / 2 + dx * (cw / 2 + roundelGap), cy);
      canvas.drawCircle(c, r, thin);
      canvas.drawCircle(c, r * 0.72, thin);
    }

    // Knotwork panels at both ends: an eight-pointed star in a square.
    final panel = inner.height * 0.86;
    for (final x in [inner.left + panel * 0.62, inner.right - panel * 0.62]) {
      final c = Offset(x, cy);
      final box = Rect.fromCenter(center: c, width: panel, height: panel);
      canvas.drawRect(box, thin);
      _star(canvas, c, panel * 0.46, thin);
      _star(canvas, c, panel * 0.24, thin);
      // Links from the panels toward the roundels.
      final towardCentre = x < w / 2 ? 1.0 : -1.0;
      final from = Offset(x + towardCentre * panel / 2, cy);
      final to = Offset(w / 2 - towardCentre * (cw / 2 + roundelGap + r), cy);
      canvas.drawLine(
        from.translate(0, -h * 0.12),
        to.translate(0, -h * 0.12),
        thin,
      );
      canvas.drawLine(
        from.translate(0, h * 0.12),
        to.translate(0, h * 0.12),
        thin,
      );
    }
  }

  void _star(Canvas canvas, Offset c, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 - math.pi / 2;
      final rr = i.isEven ? radius : radius * 0.55;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(_SurahFramePainter old) => old.color != color;
}
