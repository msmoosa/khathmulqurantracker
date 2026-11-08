import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran.dart';

/// Remembers where the reader left off and their preferred text size.
class ReaderStore extends ChangeNotifier {
  ReaderStore(this._prefs);

  static const _pageKey = 'reader_last_page';
  static const _fontKey = 'reader_font_size';

  static const minFontSize = 20.0;
  static const maxFontSize = 44.0;
  static const defaultFontSize = 28.0;

  final SharedPreferences _prefs;

  /// Last page opened in the reader, or null if it was never opened.
  int? get lastPage {
    final page = _prefs.getInt(_pageKey);
    if (page == null || page < 1 || page > mushafPageCount) return null;
    return page;
  }

  double get fontSize => (_prefs.getDouble(_fontKey) ?? defaultFontSize).clamp(
    minFontSize,
    maxFontSize,
  );

  Future<void> setLastPage(int page) async {
    if (page == lastPage) return;
    final saved = _prefs.setInt(_pageKey, page);
    notifyListeners();
    await saved;
  }

  Future<void> setFontSize(double size) async {
    final saved = _prefs.setDouble(
      _fontKey,
      size.clamp(minFontSize, maxFontSize),
    );
    notifyListeners();
    await saved;
  }
}
