import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran.dart';

/// Remembers where the reader left off.
class ReaderStore extends ChangeNotifier {
  ReaderStore(this._prefs);

  static const _pageKey = 'reader_last_page';

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
}
