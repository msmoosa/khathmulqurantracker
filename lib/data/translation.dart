import 'package:flutter/services.dart' show rootBundle;

import 'surahs.dart';

/// The Saheeh International English translation, from the Tanzil Project
/// (tanzil.net), bundled verbatim. Tanzil offers it for non-commercial use.
class Translation {
  Translation._(this._verses);

  /// Parses the Tanzil `sura|aya|text` format.
  factory Translation.parse(String raw) {
    final verses = List.generate(surahs.length, (_) => <String>[]);
    for (final line in raw.split('\n')) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('|');
      if (parts.length < 3) continue;
      verses[int.parse(parts[0]) - 1].add(parts.sublist(2).join('|').trim());
    }
    return Translation._(verses);
  }

  final List<List<String>> _verses;

  static const name = 'Saheeh International';

  static Future<Translation>? _loading;

  /// The translation, once [load] has finished.
  static Translation? loaded;

  static Future<Translation> load() => _loading ??= rootBundle
      .loadString('assets/quran/en.sahih.txt')
      .then((raw) => loaded = Translation.parse(raw));

  /// The meaning of [surah]:[verse] in English.
  String verse(int surah, int verse) => _verses[surah - 1][verse - 1];
}
