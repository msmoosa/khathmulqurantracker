import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/inspirations.dart';
import '../data/quran.dart';
import '../data/surahs.dart';
import '../state/appearance_store.dart';
import '../state/reader_store.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import '../widgets/islamic_patterns.dart';
import '../widgets/no_bold_text.dart';
import 'quran_reader_screen.dart';

/// Verses and hadith about reading the Quran, as cards to swipe through in
/// a random order, each verse a tap away in the reader.
class InspireScreen extends StatefulWidget {
  const InspireScreen({
    super.key,
    required this.reader,
    required this.tracker,
    required this.appearance,
  });

  final ReaderStore reader;
  final TrackerStore tracker;
  final AppearanceStore appearance;

  @override
  State<InspireScreen> createState() => _InspireScreenState();
}

class _InspireScreenState extends State<InspireScreen> {
  final _random = math.Random();
  final _cards = PageController(viewportFraction: 0.88);
  late List<Inspiration> _deck = _shuffled();
  var _index = 0;

  List<Inspiration> _shuffled() => [...inspirations]..shuffle(_random);

  @override
  void dispose() {
    _cards.dispose();
    super.dispose();
  }

  void _shuffle() {
    setState(() {
      _deck = _shuffled();
      _index = 0;
    });
    if (_cards.hasClients) _cards.jumpToPage(0);
  }

  void _openVerse(VerseRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderScreen(
          initialPage: pageOf(ref.surah, ref.verse),
          highlight: ref,
          reader: widget.reader,
          tracker: widget.tracker,
          appearance: widget.appearance,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<QuranText>(
      future: QuranText.load(),
      initialData: QuranText.loaded,
      builder: (context, snapshot) {
        final text = snapshot.data;
        // The text loads in a moment; nothing animates meanwhile, as this
        // tab is built in the background with the others.
        if (text == null) return const SizedBox.shrink();
        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _cards,
                itemCount: _deck.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(6, 20, 6, 8),
                  child: _InspirationCard(
                    inspiration: _deck[i],
                    text: text,
                    onOpenVerse: _openVerse,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 12, 12),
              child: Row(
                children: [
                  Text(
                    '${_index + 1} of ${_deck.length} · Swipe for more',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Shuffle',
                    icon: const Icon(Icons.shuffle_rounded),
                    onPressed: _shuffle,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InspirationCard extends StatelessWidget {
  const _InspirationCard({
    required this.inspiration,
    required this.text,
    required this.onOpenVerse,
  });

  final Inspiration inspiration;
  final QuranText text;
  final ValueChanged<VerseRef> onOpenVerse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verse = inspiration.verse;

    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        children: [
          const Positioned.fill(child: IslamicAppBarBackground()),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  verse == null ? 'HADITH' : 'QURAN',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.goldLight,
                    letterSpacing: 2,
                  ),
                ),
                Expanded(
                  // Centred, scrolling only if a long one doesn't fit.
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (verse != null) ...[
                              NoBoldText(
                                child: Text(
                                  text.verse(verse.surah, verse.verse),
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    fontFamily: quranFontFamily,
                                    fontSize: 26,
                                    height: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              '“${inspiration.meaning}”',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  verse == null
                      ? 'Narrated by ${inspiration.narrator}\n'
                            '${inspiration.source}'
                      : '${surahs[verse.surah - 1].name} '
                            '${verse.surah}:${verse.verse}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (verse != null)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => onOpenVerse(verse),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.auto_stories_outlined, size: 18),
                      label: const Text('Open in the Quran'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
