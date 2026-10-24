import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reading_entry.dart';

/// Holds the reading history and persists it to local storage.
class TrackerStore extends ChangeNotifier {
  /// [seed] replaces any stored history; it is used for demo mode, which
  /// also passes a separate [key] so real history is never overwritten.
  TrackerStore(
    this._prefs, {
    String key = 'reading_entries',
    List<ReadingEntry>? seed,
  }) : _key = key {
    if (seed != null) {
      _entries = [...seed]..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      _persist();
    } else {
      _load();
    }
  }

  final String _key;
  final SharedPreferences _prefs;
  List<ReadingEntry> _entries = [];

  /// All saved entries, oldest first.
  List<ReadingEntry> get entries => List.unmodifiable(_entries);

  /// The most recently saved position, or null if nothing has been saved.
  ReadingEntry? get lastEntry => _entries.isEmpty ? null : _entries.last;

  List<DailyCount> get daily => dailyCounts(_entries);

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    final list = jsonDecode(raw) as List<dynamic>;
    _entries =
        list
            .map((e) => ReadingEntry.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
  }

  Future<void> _persist() => _prefs.setString(
    _key,
    jsonEncode(_entries.map((e) => e.toJson()).toList()),
  );

  Future<void> save(int surah, int verse, {DateTime? at}) async {
    _entries.add(
      ReadingEntry(surah: surah, verse: verse, savedAt: at ?? DateTime.now()),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> delete(ReadingEntry entry) async {
    _entries.remove(entry);
    notifyListeners();
    await _persist();
  }
}
