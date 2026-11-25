import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mushaf_layout.dart';
import '../data/quran.dart';
import '../data/qpc_words.dart';
import '../data/surahs.dart';
import '../data/translation.dart';
import '../state/appearance_store.dart';
import '../state/mushaf_fonts.dart';
import '../state/reader_store.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../widgets/islamic_patterns.dart';
import '../widgets/no_bold_text.dart';
import '../widgets/saved_toast.dart';

/// Reads the Quran page by page as the classic Madani mushaf (1405 AH
/// print of the King Fahd Complex): the same 604 pages, each with the same
/// 15 lines, drawn in the mushaf's own calligraphy. Pages turn
/// right-to-left.
class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.initialPage,
    this.highlight,
    this.openVerseMenu = false,
    required this.reader,
    required this.tracker,
    required this.appearance,
  });

  final int initialPage;

  /// A verse on [initialPage] to highlight until the page is turned.
  final VerseRef? highlight;

  /// Whether to open [highlight]'s verse menu straight away, as if it were
  /// held. Used for store screenshots.
  final bool openVerseMenu;
  final ReaderStore reader;
  final TrackerStore tracker;
  final AppearanceStore appearance;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late final PageController _pages;
  late int _page;
  final _fonts = MushafFonts.instance;
  final _data = Future.wait([QuranText.load(), QpcWords.load()]);
  late VerseRef? _selected = widget.highlight;

  /// Whether the top bar is showing. It starts visible so the way back is
  /// obvious, hides on the first page turn, and a tap toggles it.
  var _showBar = true;

  /// Fingers on the page, for pinching the text size.
  final _pointers = <int, Offset>{};

  /// The distance between two pinching fingers when the text size last
  /// changed, or null when not pinching.
  double? _pinchBase;

  /// How far a pinch must spread (or close, inversely) to change a step.
  static const _pinchStep = 1.25;

  bool get _pinching => _pinchBase != null;

  double _pinchDistance() {
    final [a, b, ...] = _pointers.values.toList();
    return (a - b).distance;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length == 2) {
      // Holds the page still while pinching, so it doesn't turn.
      setState(() => _pinchBase = _pinchDistance());
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;
    final base = _pinchBase;
    if (base == null || _pointers.length < 2) return;
    final distance = _pinchDistance();
    if (base <= 0) {
      _pinchBase = distance;
    } else if (distance / base >= _pinchStep) {
      _stepTextSize(1, distance);
    } else if (base / distance >= _pinchStep) {
      _stepTextSize(-1, distance);
    }
  }

  void _onPointerEnd(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2 && _pinching) {
      setState(() => _pinchBase = null);
    }
  }

  /// A trackpad pinch (web and desktop), which comes as one scale.
  double _trackpadBase = 1;

  void _onPanZoomStart(PointerPanZoomStartEvent event) {
    _trackpadBase = 1;
    setState(() => _pinchBase = 1);
  }

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (event.scale / _trackpadBase >= _pinchStep) {
      _trackpadBase = event.scale;
      _stepTextSize(1, 1);
    } else if (_trackpadBase / event.scale >= _pinchStep) {
      _trackpadBase = event.scale;
      _stepTextSize(-1, 1);
    }
  }

  void _onPanZoomEnd(PointerPanZoomEndEvent event) {
    setState(() => _pinchBase = null);
  }

  /// Moves the text size a step larger or smaller, if there is one, and
  /// measures the pinch from here.
  void _stepTextSize(int delta, double distance) {
    final size = widget.reader.textSize + delta;
    if (size < 0 || size > ReaderStore.maxTextSize) return;
    _pinchBase = distance;
    HapticFeedback.selectionClick();
    widget.reader.setTextSize(size);
  }

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, mushafPageCount);
    _pages = PageController(initialPage: _page - 1);
    _prefetch(_page);
    // Saved after the first frame: this notifies listeners on the index
    // screen, which must not happen while the route is being built.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.reader.setLastPage(_page),
    );
    final held = widget.highlight;
    if (widget.openVerseMenu && held != null) {
      _data.then((data) {
        if (mounted) _onVerseTap(data[0] as QuranText, held);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Fetches the fonts of the pages either side, so turning is instant.
  void _prefetch(int page) {
    for (final p in [page, page + 1, page - 1, page + 2]) {
      if (p >= 1 && p <= mushafPageCount) _fonts.ensurePage(p);
    }
  }

  void _onPageChanged(int index) {
    _prefetch(index + 1);
    setState(() {
      _page = index + 1;
      _selected = null;
      _showBar = false;
    });
    widget.reader.setLastPage(_page);
  }

  /// A slider for the text size, applied to the page live behind it.
  void _showTextSize() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListenableBuilder(
          listenable: widget.reader,
          builder: (context, _) {
            final theme = Theme.of(context);
            final size = widget.reader.textSize;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Text size',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.text_decrease),
                      Expanded(
                        child: Slider(
                          value: size.toDouble(),
                          max: ReaderStore.maxTextSize.toDouble(),
                          divisions: ReaderStore.maxTextSize,
                          onChanged: (v) =>
                              widget.reader.setTextSize(v.round()),
                        ),
                      ),
                      const Icon(Icons.text_increase),
                    ],
                  ),
                  Text(
                    size == 0
                        ? 'As printed: each page line for line, in the '
                              "mushaf's own script."
                        : 'Larger text: the verses wrap to fit the screen, '
                              'in a simpler script.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: pinch the page to change it too.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onVerseTap(QuranText text, VerseRef ref) async {
    setState(() => _selected = ref);
    final surah = surahs[ref.surah - 1];
    final messenger = ScaffoldMessenger.of(context);

    final action = await showModalBottomSheet<_VerseAction>(
      context: context,
      showDragHandle: true,
      // Lets a long translation take the room it needs.
      isScrollControlled: true,
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
            _VerseTranslation(verse: ref),
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
        if (mounted) {
          showSavedToast(context, widget.tracker, ref.surah, ref.verse);
        }
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

    final page = FutureBuilder<List<Object>>(
      future: _data,
      initialData: QuranText.loaded != null && QpcWords.loaded != null
          ? [QuranText.loaded!, QpcWords.loaded!]
          : null,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load the Quran text.'));
        }
        if (snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final text = snapshot.data![0] as QuranText;
        final words = snapshot.data![1] as QpcWords;
        // Let a mouse drag turn pages too (web and desktop).
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(
            context,
          ).copyWith(dragDevices: {...PointerDeviceKind.values}),
          child: ListenableBuilder(
            listenable: widget.reader,
            builder: (context, _) => PageView.builder(
              controller: _pages,
              // A mushaf opens from the right, so the next page is on the left.
              reverse: true,
              itemCount: mushafPageCount,
              onPageChanged: _onPageChanged,
              physics: _pinching ? const NeverScrollableScrollPhysics() : null,
              itemBuilder: (context, i) => _ReaderPage(
                page: i + 1,
                text: text,
                words: words,
                fonts: _fonts,
                textSize: widget.reader.textSize,
                selected: _selected,
                onVerseLongPress: (ref) => _onVerseTap(text, ref),
              ),
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
              // Pinching the page changes the text size.
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerEnd,
                onPointerCancel: _onPointerEnd,
                onPointerPanZoomStart: _onPanZoomStart,
                onPointerPanZoomUpdate: _onPanZoomUpdate,
                onPointerPanZoomEnd: _onPanZoomEnd,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showBar = !_showBar),
                  child: page,
                ),
              ),
            ),
            // The text size, shown while pinching.
            IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _pinching ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: ListenableBuilder(
                    listenable: widget.reader,
                    builder: (context, _) =>
                        _TextSizeBadge(size: widget.reader.textSize),
                  ),
                ),
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
                    IconButton(
                      tooltip: 'Text size',
                      icon: const Icon(Icons.format_size),
                      onPressed: _showTextSize,
                    ),
                    IconButton(
                      tooltip: isDark ? 'Light theme' : 'Dark theme',
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      onPressed: () => widget.appearance.setThemeMode(
                        isDark ? ThemeMode.light : ThemeMode.dark,
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

/// The verse's meaning in English, in the verse menu. A long one scrolls
/// within at most half the screen.
class _VerseTranslation extends StatelessWidget {
  const _VerseTranslation({required this.verse});

  final VerseRef verse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<Translation>(
      future: Translation.load(),
      initialData: Translation.loaded,
      builder: (context, snapshot) {
        final translation = snapshot.data;
        if (translation == null) return const SizedBox.shrink();
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translation.verse(verse.surah, verse.verse),
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 6),
                Text(
                  Translation.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Lines per page of the Madani mushaf.
const _linesPerPage = 15;

/// Line height as a multiple of the font size; the Uthmani script needs
/// room above and below for its marks.
const _lineHeightFactor = 1.9;

/// Below this font size a page no longer fits the screen legibly (e.g. in
/// landscape), so it is sized to the width and scrolls instead.
const _minFittedFontSize = 15.0;

/// Line height of the 8-line opening pages, as a multiple of the font size.
const _openingLineHeightFactor = 2.3;

/// Line height of reflowed text, as a multiple of the font size: looser
/// than print, so the marks of one line keep clear of the next.
const _reflowLineHeightFactor = 2.5;

/// Smallest gap between words, as a multiple of the font size.
const _gapFactor = 0.18;

/// A line of a mushaf page.
sealed class _Line {
  const _Line();
}

class _HeaderLine extends _Line {
  const _HeaderLine(this.surah);
  final int surah;
}

class _BismillahLine extends _Line {
  const _BismillahLine();
}

class _WordsLine extends _Line {
  const _WordsLine(this.words);
  final List<_Word> words;
}

class _Word {
  const _Word(this.ref, this.text);
  final VerseRef ref;
  final String text;
}

/// Paints the selected verse's highlight under a word or a gap. Each
/// piece reaches a little past its box so that neighbours overlap rather
/// than leave a seam, and only the ends of a run are rounded.
class _BarPainter extends CustomPainter {
  const _BarPainter({this.roundStart = false, this.roundEnd = false});

  /// Whether to round the start (right, in Arabic) or end of the bar.
  final bool roundStart;
  final bool roundEnd;

  @override
  void paint(Canvas canvas, Size size) {
    const r = Radius.circular(4);
    final rect = (Offset.zero & size).inflate(0.5);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topRight: roundStart ? r : Radius.zero,
        bottomRight: roundStart ? r : Radius.zero,
        topLeft: roundEnd ? r : Radius.zero,
        bottomLeft: roundEnd ? r : Radius.zero,
      ),
      Paint()..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.roundStart != roundStart || old.roundEnd != roundEnd;
}

/// A pill naming the text size, shown over the page while pinching.
class _TextSizeBadge extends StatelessWidget {
  const _TextSizeBadge({required this.size});

  final int size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(170),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_size, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              size == 0
                  ? 'As printed'
                  : 'Size $size of ${ReaderStore.maxTextSize}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a page in the mushaf's own calligraphy once its font is ready,
/// or in the bundled Uthmani font if the page font cannot be fetched.
class _ReaderPage extends StatelessWidget {
  const _ReaderPage({
    required this.page,
    required this.text,
    required this.words,
    required this.fonts,
    required this.textSize,
    required this.selected,
    required this.onVerseLongPress,
  });

  final int page;
  final QuranText text;
  final QpcWords words;
  final MushafFonts fonts;

  /// [ReaderStore.textSize]: above 0 the page is reflowed, which needs
  /// only the bundled font.
  final int textSize;
  final VerseRef? selected;
  final ValueChanged<VerseRef> onVerseLongPress;

  List<_Line> _lines({required bool calligraphy}) {
    final layout = mushafLines[page - 1];
    final result = <_Line>[];
    for (var i = 0; i < layout.length; i++) {
      final value = layout[i];
      if (value == bismillahLine) {
        result.add(const _BismillahLine());
      } else if (value < 0) {
        result.add(_HeaderLine(-value));
      } else if (calligraphy) {
        result.add(
          _WordsLine([
            for (final w in words.line(page, i + 1)!) _Word(w.ref, w.glyphs),
          ]),
        );
      } else {
        // Fallback: the tokens from this line's start to the next line's.
        final next = layout
            .skip(i + 1)
            .firstWhere(
              (l) => l >= 0,
              orElse: () => page == mushafPageCount
                  ? text.tokens.length
                  : mushafLines[page].firstWhere((l) => l >= 0),
            );
        result.add(
          _WordsLine([
            for (final t in text.tokens.sublist(value, next))
              _Word(t.ref, t.text),
          ]),
        );
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (textSize > 0) {
      return _BookPage(
        page: page,
        lines: _lines(calligraphy: false),
        textSize: textSize,
        selected: selected,
        onVerseLongPress: onVerseLongPress,
      );
    }
    return FutureBuilder<bool>(
      future: fonts.ensurePage(page),
      initialData: fonts.isPageReady(page) ? true : null,
      builder: (context, snapshot) {
        final ready = snapshot.data;
        if (ready == null) {
          return _BookPage(page: page, lines: null);
        }
        return ListenableBuilder(
          listenable: fonts,
          builder: (context, _) => _BookPage(
            page: page,
            lines: _lines(calligraphy: ready),
            fontFamily: ready ? MushafFonts.pageFamily(page) : quranFontFamily,
            fallbackNotice: !ready,
            selected: selected,
            onVerseLongPress: onVerseLongPress,
          ),
        );
      },
    );
  }
}

/// One page of the mushaf, line for line as printed.
class _BookPage extends StatelessWidget {
  const _BookPage({
    required this.page,
    required this.lines,
    this.fontFamily = quranFontFamily,
    this.fallbackNotice = false,
    this.textSize = 0,
    this.selected,
    this.onVerseLongPress,
  });

  final int page;

  /// The page's lines, or null while its font is loading.
  final List<_Line>? lines;
  final String fontFamily;

  /// Whether to say that the page is shown in the fallback script.
  final bool fallbackNotice;

  /// 0 to lay the page out as printed, or a larger size to reflow it.
  final int textSize;
  final VerseRef? selected;
  final ValueChanged<VerseRef>? onVerseLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = pageStart(page);
    final surah = surahs[pageSurah(page) - 1];
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page caption, as in the margin of a printed mushaf.
          Text(
            '${surah.name}, Juz ${juzOf(start.surah, start.verse)}, '
            'Hizb ${hizbLabel(start.surah, start.verse)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: lines == null
                ? const Center(
                    child: SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : NoBoldText(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: LayoutBuilder(
                        builder: (context, constraints) => textSize > 0
                            ? _buildReflow(context, constraints, lines!)
                            : _buildLines(context, constraints, lines!),
                      ),
                    ),
                  ),
          ),
          // Page number at the foot of the page, as in print.
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$page',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (fallbackNotice)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Simplified script: connect to the internet to load this '
                "page's mushaf font.",
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLines(
    BuildContext context,
    BoxConstraints constraints,
    List<_Line> lines,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = constraints.maxWidth;

    // Size the text so the widest line fits the width and all 15 lines fit
    // the height, then justify every line to the full width like print.
    const baseSize = 20.0;
    final base = TextStyle(fontFamily: fontFamily, fontSize: baseSize);
    // Natural width of every word, with its share of the minimum gap.
    final wordWidths = [
      for (final line in lines)
        line is _WordsLine
            ? [
                for (final w in line.words)
                  _measure(w.text, base) + _gapFactor * baseSize,
              ]
            : const <double>[],
    ];
    final natural = [
      for (final widths in wordWidths) widths.fold(0.0, (a, b) => a + b),
    ];
    final widest = natural.fold(0.0, math.max);
    final widthFit = widest == 0 ? 28.0 : baseSize * width * 0.99 / widest;
    final heightFit = constraints.maxHeight / _linesPerPage / _lineHeightFactor;
    final scrolls = heightFit < _minFittedFontSize;
    // The opening pages have only 8 lines. As in print, they are set a
    // little larger and centred on the page rather than left half empty.
    final opening = lines.length < _linesPerPage;
    final openingFit = math.min(
      constraints.maxHeight / lines.length / _openingLineHeightFactor,
      heightFit * 1.35,
    );
    final fontSize = scrolls
        ? math.min(widthFit, 30.0)
        : math.min(widthFit, opening ? openingFit : heightFit);
    // Spread the lines over the whole page, as in print.
    final lineHeight = scrolls
        ? fontSize * _lineHeightFactor
        : opening
        ? fontSize * _openingLineHeightFactor
        : math.max(
            fontSize * _lineHeightFactor,
            constraints.maxHeight / _linesPerPage,
          );

    final ink = isDark ? AppColors.paper : AppColors.ink;
    final wordStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: 1,
      color: ink,
    );
    final reveal = _Reveal(selected);

    final rows = <Widget>[];
    final bars = <Widget>[];
    for (final (i, line) in lines.indexed) {
      final Widget row = switch (line) {
        _BismillahLine() => _glyphToWidth(
          '\uFDFD',
          MushafFonts.bismillahFamily,
          // As wide as in print, but never taller than its line.
          math.min(width * 0.82, lineHeight * 9),
          ink,
        ),
        _HeaderLine(:final surah) => _SurahHeader(
          surah: surah,
          height: lineHeight * 0.95,
          color: ink,
        ),
        _WordsLine(:final words) => _wordRow(
          words,
          wordStyle,
          lineHeight,
          reveal,
          bars,
          (cell, gap) =>
              // Short lines (the opening pages, or where a surah ends) are
              // centred rather than stretched.
              page <= 2 || natural[i] * fontSize / baseSize < width * 0.75
              // Scaled down rather than clipped if a line ever measures
              // wider than expected (e.g. a fallback font).
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      for (var k = 0; k < words.length; k++) ...[
                        if (k > 0)
                          SizedBox(
                            width: fontSize * 0.2,
                            height: lineHeight,
                            child: gap(k),
                          ),
                        cell(k),
                      ],
                    ],
                  ),
                )
              // Justify by giving each word a share of the spare width in
              // proportion to its size, so the whole line can be held.
              : Row(
                  children: [
                    for (var k = 0; k < words.length; k++)
                      Expanded(
                        flex: math.max(1, (wordWidths[i][k] * 10).round()),
                        child: cell(k),
                      ),
                  ],
                ),
        ),
      };
      if (bars.length == rows.length) bars.add(const SizedBox.shrink());
      rows.add(SizedBox(height: lineHeight, child: row));
      bars.last = SizedBox(height: lineHeight, child: bars.last);
    }

    final column = _layered(rows, bars, isDark);
    if (scrolls) {
      return _RevealSelected(
        reveal: reveal,
        child: SingleChildScrollView(child: column),
      );
    }
    return Align(
      alignment: opening ? Alignment.center : Alignment.topCenter,
      child: column,
    );
  }

  /// Lays out a line of [words] with [arrange], which places each word's
  /// cell and the gap before it. Returns the line as text, and adds the
  /// same layout to [bars] with the selected verse's highlight in place of
  /// the text, if the verse is on this line.
  Widget _wordRow(
    List<_Word> words,
    TextStyle style,
    double height,
    _Reveal reveal,
    List<Widget> bars,
    Widget Function(Widget Function(int k) cell, Widget? Function(int k) gap)
    arrange,
  ) {
    bool lit(int k) => k >= 0 && k < words.length && words[k].ref == selected;
    if (words.any((w) => w.ref == selected)) {
      final ghost = style.copyWith(color: Colors.transparent);
      bars.add(
        arrange(
          (k) => CustomPaint(
            painter: lit(k)
                ? _BarPainter(roundStart: !lit(k - 1), roundEnd: !lit(k + 1))
                : null,
            child: _cellBody(words[k], ghost, height),
          ),
          (k) => lit(k - 1) && lit(k)
              ? const CustomPaint(painter: _BarPainter())
              : null,
        ),
      );
    }
    return arrange(
      (k) => _wordCell(words[k], style, height, key: reveal.keyFor(words[k])),
      (k) => null,
    );
  }

  /// The page's lines over their highlight [bars], which are drawn
  /// together beneath all the text so that the marks of one line never
  /// sit under the next line's highlight, and so that where the bars meet
  /// or overlap they blend into one.
  static Widget _layered(List<Widget> rows, List<Widget> bars, bool isDark) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
    if (bars.every((b) => b is SizedBox && b.child is SizedBox)) {
      return column;
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        IgnorePointer(
          child: Opacity(
            opacity: (isDark ? 80 : 70) / 255,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: bars,
            ),
          ),
        ),
        column,
      ],
    );
  }

  /// A word that can be held to open its verse's menu.
  Widget _wordCell(_Word w, TextStyle style, double height, {Key? key}) {
    return GestureDetector(
      key: key,
      // Opaque so the whole cell, not just the glyphs, can be held.
      behavior: HitTestBehavior.opaque,
      onLongPress: () => onVerseLongPress?.call(w.ref),
      child: _cellBody(w, style, height),
    );
  }

  static Widget _cellBody(_Word w, TextStyle style, double height) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: style.fontSize! * _gapFactor / 2,
      ),
      // Only as wide as the word, so a reflowed line can hold several;
      // in a printed line the cell is given its width.
      child: Center(
        widthFactor: 1,
        child: Text(
          w.text,
          textScaler: TextScaler.noScaling,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: style,
        ),
      ),
    );
  }

  /// The page's verses set larger than print, wrapping to the width and
  /// scrolling, with its surah frames and Bismillah kept in place.
  Widget _buildReflow(
    BuildContext context,
    BoxConstraints constraints,
    List<_Line> lines,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.paper : AppColors.ink;
    final fontSize = 22.0 + 5 * textSize;
    final lineHeight = fontSize * _reflowLineHeightFactor;
    final wordStyle = TextStyle(
      fontFamily: quranFontFamily,
      fontSize: fontSize,
      height: 1,
      color: ink,
    );
    final blocks = <Widget>[];
    final bars = <Widget>[];
    var run = <_Word>[];
    // Breaks a run of words into lines that fill the width, and justifies
    // each by spreading its words to both edges, as in print. The run's
    // last line is set from the right instead.
    final width = constraints.maxWidth;
    final reveal = _Reveal(selected);
    // Adds a block of the page, and an empty bar to match it unless its
    // highlight was just added.
    void addBlock(double height, Widget block) {
      if (bars.length == blocks.length) bars.add(const SizedBox.shrink());
      blocks.add(SizedBox(height: height, child: block));
      bars.last = SizedBox(height: height, child: bars.last);
    }

    void endRun() {
      if (run.isEmpty) return;
      final lines = <List<_Word>>[[]];
      var used = 0.0;
      for (final w in run) {
        final size = _measure(w.text, wordStyle) + fontSize * _gapFactor;
        if (lines.last.isNotEmpty && used + size > width) {
          lines.add([]);
          used = 0;
        }
        lines.last.add(w);
        used += size;
      }
      for (final (i, line) in lines.indexed) {
        final last = i == lines.length - 1;
        final row = _wordRow(
          line,
          wordStyle,
          lineHeight,
          reveal,
          bars,
          (cell, gap) => line.length == 1
              // A lone word too wide for the screen is scaled down to fit.
              ? FittedBox(fit: BoxFit.scaleDown, child: cell(0))
              : Row(
                  children: [
                    for (var k = 0; k < line.length; k++) ...[
                      // The spare width is shared out between the words.
                      if (k > 0 && !last)
                        Expanded(
                          child: SizedBox(height: lineHeight, child: gap(k)),
                        ),
                      cell(k),
                    ],
                  ],
                ),
        );
        addBlock(lineHeight, row);
      }
      run = [];
    }

    // The banner and Bismillah stay the size they are in print.
    const bannerHeight = 52.0;
    for (final line in lines) {
      switch (line) {
        case _WordsLine(:final words):
          run.addAll(words);
        case _HeaderLine(:final surah):
          endRun();
          addBlock(
            bannerHeight,
            _SurahHeader(surah: surah, height: bannerHeight * 0.95, color: ink),
          );
        case _BismillahLine():
          endRun();
          addBlock(
            bannerHeight,
            _glyphToWidth(
              '\uFDFD',
              MushafFonts.bismillahFamily,
              math.min(constraints.maxWidth * 0.82, bannerHeight * 9),
              ink,
            ),
          );
      }
    }
    endRun();

    return _RevealSelected(
      reveal: reveal,
      child: SingleChildScrollView(
        // Room for the marks above the first line and below the last, which
        // reach past their line boxes and would be clipped at the edges.
        padding: EdgeInsets.symmetric(vertical: fontSize * 0.6),
        child: _layered(blocks, bars, isDark),
      ),
    );
  }

  /// Draws a single decorative glyph (a surah frame or the Bismillah) at
  /// [targetWidth]. These glyphs sit in very tall line boxes, so they are
  /// sized by their measured width and allowed to overflow vertically.
  static Widget _glyphToWidth(
    String glyph,
    String family,
    double targetWidth,
    Color color,
  ) {
    const probe = 100.0;
    final measured = _measure(
      glyph,
      TextStyle(fontFamily: family, fontSize: probe),
    );
    final size = measured == 0 ? probe : probe * targetWidth / measured;
    return ClipRect(
      child: OverflowBox(
        maxHeight: double.infinity,
        child: Center(
          child: Text(
            glyph,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: family,
              fontSize: size,
              height: 1,
              color: color,
            ),
          ),
        ),
      ),
    );
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

/// Marks the first word of the selected verse on a page being built, so
/// [_RevealSelected] can scroll to it.
class _Reveal {
  _Reveal(this.selected);

  final VerseRef? selected;
  final target = GlobalKey();
  var _marked = false;

  /// The key for [w] if it is the first word of the selected verse.
  Key? keyFor(_Word w) {
    if (_marked || w.ref != selected) return null;
    _marked = true;
    return target;
  }
}

/// Scrolls a page that is taller than the screen to the selected verse
/// when it opens, or when another verse is selected, unless the verse is
/// already in view.
class _RevealSelected extends StatefulWidget {
  const _RevealSelected({required this.reveal, required this.child});

  final _Reveal reveal;
  final Widget child;

  @override
  State<_RevealSelected> createState() => _RevealSelectedState();
}

class _RevealSelectedState extends State<_RevealSelected> {
  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(_RevealSelected old) {
    super.didUpdateWidget(old);
    if (old.reveal.selected != widget.reveal.selected) _reveal();
  }

  void _reveal() {
    if (widget.reveal.selected == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final word = widget.reveal.target.currentContext;
      if (!mounted || word == null) return;
      final viewport = Scrollable.maybeOf(word)?.context.findRenderObject();
      if (viewport is! RenderBox) return;
      final box = word.findRenderObject()! as RenderBox;
      final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      if (top >= 0 && top + box.size.height <= viewport.size.height) return;
      Scrollable.ensureVisible(
        word,
        alignment: 0.3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
            // "سورة <name>" in the 1405 AH calligraphy.
            child: Text(
              'surah${surah.toString().padLeft(3, '0')}',
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: MushafFonts.surahNameFamily,
                fontSize: height * 0.62,
                height: 1,
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
