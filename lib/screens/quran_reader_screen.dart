import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/quran.dart';
import '../data/quran_meta.dart';
import '../data/surahs.dart';
import '../state/reader_store.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../widgets/islamic_patterns.dart';

/// Reads the Quran page by page in the Uthmani script, following the
/// 604-page layout of the Madani mushaf. Pages turn right-to-left.
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

  void _showTextSize() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: ListenableBuilder(
            listenable: widget.reader,
            builder: (context, _) {
              final size = widget.reader.fontSize;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Text size',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: quranFontFamily,
                      fontSize: size,
                      height: 1.8,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.text_decrease_rounded),
                      Expanded(
                        child: Slider(
                          value: size,
                          min: ReaderStore.minFontSize,
                          max: ReaderStore.maxFontSize,
                          divisions: 12,
                          onChanged: widget.reader.setFontSize,
                        ),
                      ),
                      const Icon(Icons.text_increase_rounded),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
        actions: [
          IconButton(
            tooltip: 'Text size',
            icon: const Icon(Icons.format_size_rounded),
            onPressed: _showTextSize,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<QuranText>(
          future: _text,
          initialData: QuranText.loaded,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Could not load the Quran text.'));
            }
            final text = snapshot.data;
            if (text == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListenableBuilder(
              listenable: widget.reader,
              // Let a mouse drag turn pages too (web and desktop).
              builder: (context, _) => ScrollConfiguration(
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
                  itemBuilder: (context, i) => _MushafPage(
                    page: i + 1,
                    text: text,
                    fontSize: widget.reader.fontSize,
                    selected: _selected,
                    onVerseTap: (ref) => _onVerseTap(text, ref),
                  ),
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

class _MushafPage extends StatefulWidget {
  const _MushafPage({
    required this.page,
    required this.text,
    required this.fontSize,
    required this.selected,
    required this.onVerseTap,
  });

  final int page;
  final QuranText text;
  final double fontSize;
  final VerseRef? selected;
  final ValueChanged<VerseRef> onVerseTap;

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  final _recognizers = <VerseRef, TapGestureRecognizer>{};

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recognizer(VerseRef ref) =>
      (_recognizers[ref] ??= TapGestureRecognizer())
        ..onTap = () => widget.onVerseTap(ref);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final markerColor = isDark ? AppColors.gold : AppColors.emeraldLight;
    final textStyle = TextStyle(
      fontFamily: quranFontFamily,
      fontSize: widget.fontSize,
      height: 2.1,
      color: theme.colorScheme.onSurface,
    );
    final highlight = AppColors.gold.withAlpha(isDark ? 70 : 60);
    // The first two pages of a mushaf are set in short, centred lines.
    final align = widget.page <= 2 ? TextAlign.center : TextAlign.justify;

    final children = <Widget>[];
    for (final segment in pageSegments(widget.page)) {
      if (segment.startsSurah) {
        children.add(_SurahHeader(surah: segment.surah));
        if (segment.surah != 1 && segment.surah != 9) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.text.bismillah,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ),
          );
        }
      }
      children.add(
        Text.rich(
          TextSpan(
            children: [
              for (var v = segment.firstVerse; v <= segment.lastVerse; v++)
                _verseSpan(
                  VerseRef(segment.surah, v),
                  highlight: highlight,
                  markerColor: markerColor,
                ),
            ],
          ),
          textAlign: align,
          style: textStyle,
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        key: PageStorageKey('mushaf-page-${widget.page}'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...children,
            const SizedBox(height: 16),
            const IslamicDivider(),
            const SizedBox(height: 4),
            Text(
              arabicNumber(widget.page),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: quranFontFamily,
                fontSize: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InlineSpan _verseSpan(
    VerseRef ref, {
    required Color highlight,
    required Color markerColor,
  }) {
    final selected = widget.selected == ref;
    final background = selected ? highlight : null;
    final recognizer = _recognizer(ref);
    return TextSpan(
      children: [
        TextSpan(
          text: widget.text.verse(ref.surah, ref.verse),
          recognizer: recognizer,
          style: TextStyle(backgroundColor: background),
        ),
        // Non-breaking space keeps the verse number on the verse's line.
        // U+06DD followed by digits renders as an ornamented end-of-verse
        // marker in the Uthmani font.
        TextSpan(
          text: ' ۝${arabicNumber(ref.verse)} ',
          recognizer: recognizer,
          style: TextStyle(color: markerColor, backgroundColor: background),
        ),
      ],
    );
  }
}

/// Ornamental banner that opens a surah.
class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});

  final int surah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = surahs[surah - 1];
    final small = theme.textTheme.labelSmall?.copyWith(
      color: AppColors.goldLight,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ),
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const IslamicAppBarBackground(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        surahIsMeccan[surah - 1] ? 'مكية' : 'مدنية',
                        style: small?.copyWith(fontFamily: quranFontFamily),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'سورة ${surahArabicNames[surah - 1]}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: quranFontFamily,
                          fontSize: 24,
                          height: 1.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        'آياتها ${arabicNumber(info.verseCount)}',
                        textAlign: TextAlign.left,
                        style: small?.copyWith(fontFamily: quranFontFamily),
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
