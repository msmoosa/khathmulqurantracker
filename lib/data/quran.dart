import 'package:flutter/services.dart' show rootBundle;

import 'quran_meta.dart';
import 'surahs.dart';

/// Font used to render the Uthmani script.
const quranFontFamily = 'AmiriQuran';

/// Number of pages in the Madani mushaf.
const int mushafPageCount = 604;

/// A (surah, verse) position.
class VerseRef {
  const VerseRef(this.surah, this.verse);

  final int surah;
  final int verse;

  int get absolute => absoluteVerse(surah, verse);

  @override
  bool operator ==(Object other) =>
      other is VerseRef && other.surah == surah && other.verse == verse;

  @override
  int get hashCode => Object.hash(surah, verse);

  @override
  String toString() => '$surah:$verse';
}

/// A run of consecutive verses from one surah, as shown on a mushaf page.
class PageSegment {
  const PageSegment(this.surah, this.firstVerse, this.lastVerse);

  final int surah;
  final int firstVerse;
  final int lastVerse;

  /// Whether this segment opens the surah, so it gets a surah header.
  bool get startsSurah => firstVerse == 1;
}

/// Converts a 1-based index across the whole Quran back to (surah, verse).
VerseRef verseAt(int absolute) {
  var remaining = absolute;
  for (final s in surahs) {
    if (remaining <= s.verseCount) return VerseRef(s.number, remaining);
    remaining -= s.verseCount;
  }
  throw RangeError.range(absolute, 1, totalVerses, 'absolute');
}

VerseRef _startAt(List<int> flat, int index) =>
    VerseRef(flat[index * 2], flat[index * 2 + 1]);

/// First verse of [page] (1-604).
VerseRef pageStart(int page) => _startAt(pageStarts, page - 1);

/// Finds the last entry in a flattened start table at or before [ref].
int _lastStartAtOrBefore(List<int> flat, VerseRef ref) {
  final target = ref.absolute;
  var lo = 0;
  var hi = flat.length ~/ 2 - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) ~/ 2;
    if (_startAt(flat, mid).absolute <= target) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return lo + 1;
}

/// Mushaf page (1-604) that [surah]:[verse] is on.
int pageOf(int surah, int verse) =>
    _lastStartAtOrBefore(pageStarts, VerseRef(surah, verse));

/// Juz (1-30) that [surah]:[verse] is in.
int juzOf(int surah, int verse) =>
    _lastStartAtOrBefore(juzStarts, VerseRef(surah, verse));

/// First verse of [juz] (1-30).
VerseRef juzStart(int juz) => _startAt(juzStarts, juz - 1);

/// The verses on [page], split by surah.
List<PageSegment> pageSegments(int page) {
  final first = pageStart(page).absolute;
  final last = page < mushafPageCount
      ? pageStart(page + 1).absolute - 1
      : totalVerses;
  final end = verseAt(last);
  final segments = <PageSegment>[];
  var ref = verseAt(first);
  while (ref.surah < end.surah) {
    segments.add(
      PageSegment(ref.surah, ref.verse, surahs[ref.surah - 1].verseCount),
    );
    ref = VerseRef(ref.surah + 1, 1);
  }
  segments.add(PageSegment(ref.surah, ref.verse, end.verse));
  return segments;
}

/// Surah named in the header of [page]: the last surah that appears on it,
/// as in a printed mushaf.
int pageSurah(int page) => pageSegments(page).last.surah;

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

/// Formats [n] with Arabic-Indic digits, e.g. 12 -> ١٢.
String arabicNumber(int n) =>
    n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join();

/// The Uthmani text of the Quran (Tanzil Project, tanzil.net).
class QuranText {
  QuranText._(this._verses, this.bismillah);

  /// Parses the Tanzil `sura|aya|text` format.
  factory QuranText.parse(String raw) {
    final verses = List.generate(surahs.length, (_) => <String>[]);
    for (final line in raw.split('\n')) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('|');
      if (parts.length < 3) continue;
      verses[int.parse(parts[0]) - 1].add(parts.sublist(2).join('|').trim());
    }
    final bismillah = verses[0][0];
    // Every surah but Al-Fatihah and At-Tawbah opens with the Bismillah as
    // part of its first verse. A printed mushaf shows it above the surah
    // instead, so drop its four words from the verse text.
    for (var s = 2; s <= surahs.length; s++) {
      if (s == 9) continue;
      final words = verses[s - 1][0].split(' ');
      verses[s - 1][0] = words.skip(4).join(' ');
    }
    return QuranText._(verses, bismillah);
  }

  final List<List<String>> _verses;

  /// The Bismillah (Al-Fatihah verse 1).
  final String bismillah;

  static Future<QuranText>? _loading;

  /// The text, once [load] has finished.
  static QuranText? loaded;

  /// Loads and caches the bundled text.
  static Future<QuranText> load() => _loading ??= rootBundle
      .loadString('assets/quran/quran-uthmani.txt')
      .then((raw) => loaded = QuranText.parse(raw));

  /// Text of [surah]:[verse], without a leading Bismillah.
  String verse(int surah, int verse) => _verses[surah - 1][verse - 1];
}
