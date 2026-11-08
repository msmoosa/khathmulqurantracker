import 'package:flutter/services.dart' show rootBundle;

import 'quran.dart';

/// One word of the classic Madani mushaf (or a verse-end marker), as the
/// characters that draw it in its page's QPC V1 font.
class QpcWord {
  const QpcWord(this.ref, this.glyphs);

  final VerseRef ref;
  final String glyphs;
}

/// Glyph codes for every text line of the 604 pages of the QPC V1 mushaf.
class QpcWords {
  QpcWords._(this._lines);

  /// Parses lines of `page<TAB>line<TAB>surah:verse:glyphs|...`.
  factory QpcWords.parse(String raw) {
    final lines = <int, Map<int, List<QpcWord>>>{};
    for (final row in raw.split('\n')) {
      if (row.isEmpty || row.startsWith('#')) continue;
      final cols = row.split('\t');
      final words = <QpcWord>[];
      for (final item in cols[2].split('|')) {
        final a = item.indexOf(':');
        final b = item.indexOf(':', a + 1);
        words.add(
          QpcWord(
            VerseRef(
              int.parse(item.substring(0, a)),
              int.parse(item.substring(a + 1, b)),
            ),
            item.substring(b + 1),
          ),
        );
      }
      (lines[int.parse(cols[0])] ??= {})[int.parse(cols[1])] = words;
    }
    return QpcWords._(lines);
  }

  final Map<int, Map<int, List<QpcWord>>> _lines;

  /// Words on [line] (1-based) of [page], or null for a line that holds a
  /// surah header or the Bismillah.
  List<QpcWord>? line(int page, int line) => _lines[page]?[line];

  static Future<QpcWords>? _loading;

  /// The words, once [load] has finished.
  static QpcWords? loaded;

  static Future<QpcWords> load() => _loading ??= rootBundle
      .loadString('assets/quran/qpc-v1-words.txt')
      .then((raw) => loaded = QpcWords.parse(raw));
}
