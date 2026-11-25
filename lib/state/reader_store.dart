import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran.dart';

/// Remembers where the reader left off, and its text size.
class ReaderStore extends ChangeNotifier {
  ReaderStore(this._prefs);

  static const _pageKey = 'reader_last_page';
  static const _textSizeKey = 'reader_text_size';
  static const _surahMarksKey = 'surah_marks';

  final SharedPreferences _prefs;

  /// Last page opened in the reader, or null if it was never opened.
  int? get lastPage {
    final page = _prefs.getInt(_pageKey);
    if (page == null || page < 1 || page > mushafPageCount) return null;
    return page;
  }

  Future<void> setLastPage(int page) async {
    if (page == lastPage) return;
    final saved = _prefs.setInt(_pageKey, page);
    notifyListeners();
    await saved;
  }

  /// Largest [textSize] step.
  static const maxTextSize = 4;

  /// The reader's text size: 0 lays pages out as printed, and each step
  /// above that sets the text larger, wrapping the verses to the screen.
  int get textSize =>
      (_prefs.getInt(_textSizeKey) ?? 0).clamp(0, maxTextSize).toInt();

  Future<void> setTextSize(int size) async {
    if (size == textSize) return;
    final saved = _prefs.setInt(_textSizeKey, size);
    notifyListeners();
    await saved;
  }

  /// Surah marks: one per surah at most, keeping the reader's place in a
  /// surah read again and again (e.g. al-Kahf on Fridays). They are
  /// separate from the khathm tracker. Keyed by surah, to the verse.
  Map<int, int> get surahMarks {
    final raw = _prefs.getString(_surahMarksKey);
    if (raw == null) return const {};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in json.entries)
          if (int.tryParse(e.key) case final surah?)
            if (e.value case final int verse) surah: verse,
      };
    } on FormatException {
      return const {};
    }
  }

  /// The verse marked in [surah], or null.
  int? surahMark(int surah) => surahMarks[surah];

  /// Marks [ref], moving its surah's mark if it had one.
  Future<void> setSurahMark(VerseRef ref) =>
      _saveMarks({...surahMarks, ref.surah: ref.verse});

  Future<void> removeSurahMark(int surah) =>
      _saveMarks({...surahMarks}..remove(surah));

  Future<void> _saveMarks(Map<int, int> marks) async {
    final saved = _prefs.setString(
      _surahMarksKey,
      jsonEncode({for (final e in marks.entries) '${e.key}': e.value}),
    );
    notifyListeners();
    await saved;
  }
}
