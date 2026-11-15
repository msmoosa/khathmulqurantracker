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

/// Verses and hadith about reading the Quran, played like stories: each
/// card shows for a while and moves on by itself, in a random order. Tap
/// the right side for the next card or the left for the previous, swipe
/// between them, or hold to pause.
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

class _InspireScreenState extends State<InspireScreen>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  final _cards = PageController();
  late final _timer = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });
  late List<Inspiration> _deck = _shuffled();
  var _index = 0;

  /// Whether this tab is showing, with nothing on top of it.
  var _onScreen = false;

  /// Whether the card is being held.
  var _held = false;

  List<Inspiration> _shuffled() => [...inspirations]..shuffle(_random);

  /// How long a card shows: long enough to read it twice over.
  static Duration _durationOf(Inspiration i) =>
      Duration(milliseconds: math.min(5000 + 45 * i.meaning.length, 15000));

  @override
  void initState() {
    super.initState();
    _timer.duration = _durationOf(_deck[0]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The tab bar keeps every tab alive, so hold the story while another
    // tab is showing or a page is open on top of this one.
    _onScreen = Visibility.of(context) && TickerMode.valuesOf(context).enabled;
    _play();
  }

  @override
  void dispose() {
    _timer.dispose();
    _cards.dispose();
    super.dispose();
  }

  /// Runs the current card's timer, unless it should be paused.
  void _play() {
    if (_onScreen && !_held) {
      _timer.forward();
    } else {
      _timer.stop();
    }
  }

  void _show(int index) {
    _cards.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_index < _deck.length - 1) return _show(_index + 1);
    // After the last card, start again in a new order.
    setState(() => _deck = _shuffled());
    _cards.jumpToPage(0);
    _onPageChanged(0);
  }

  void _previous() {
    if (_index > 0) return _show(_index - 1);
    _timer.value = 0;
    _play();
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _timer
      ..duration = _durationOf(_deck[index])
      ..value = 0;
    _play();
  }

  void _hold(bool held) {
    setState(() => _held = held);
    _play();
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
    return FutureBuilder<QuranText>(
      future: QuranText.load(),
      initialData: QuranText.loaded,
      builder: (context, snapshot) {
        final text = snapshot.data;
        // The text loads in a moment; nothing animates meanwhile, as this
        // tab is built in the background with the others.
        if (text == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                const Positioned.fill(child: IslamicAppBarBackground()),
                LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) =>
                        details.localPosition.dx < constraints.maxWidth / 3
                        ? _previous()
                        : _next(),
                    onLongPressStart: (_) => _hold(true),
                    onLongPressEnd: (_) => _hold(false),
                    child: PageView.builder(
                      controller: _cards,
                      itemCount: _deck.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, i) => _InspirationCard(
                        inspiration: _deck[i],
                        text: text,
                        onOpenVerse: _openVerse,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 14,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _timer,
                      builder: (context, _) => _StoryProgress(
                        count: _deck.length,
                        index: _index,
                        progress: _timer.value,
                      ),
                    ),
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

/// A bar per card along the top, as in stories: the cards seen are full,
/// the current one fills as it plays.
class _StoryProgress extends StatelessWidget {
  const _StoryProgress({
    required this.count,
    required this.index,
    required this.progress,
  });

  final int count;
  final int index;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: i < index
                    ? 1
                    : i == index
                    ? progress
                    : 0,
                minHeight: 3,
                backgroundColor: Colors.white.withAlpha(60),
                valueColor: const AlwaysStoppedAnimation(AppColors.goldLight),
              ),
            ),
          ),
        ],
      ],
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

    return Padding(
      // Clear of the progress bars along the top.
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                              fontSize: 28,
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
                        style: theme.textTheme.titleLarge?.copyWith(
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
                ? 'Narrated by ${inspiration.narrator}\n${inspiration.source}'
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
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.auto_stories_outlined, size: 18),
                label: const Text('Open in the Quran'),
              ),
            ),
        ],
      ),
    );
  }
}
