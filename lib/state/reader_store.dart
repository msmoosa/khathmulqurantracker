import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran.dart';

/// Remembers where the reader left off, and its text size.
class ReaderStore extends ChangeNotifier {
  ReaderStore(this._prefs);

  static const _pageKey = 'reader_last_page';
  static const _textSizeKey = 'reader_text_size';

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
}
