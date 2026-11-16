import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/data/surahs.dart';
import 'package:khathmtracker/data/translation.dart';

void main() {
  test('the translation has every verse of every surah', () {
    final t = Translation.parse(
      File('assets/quran/en.sahih.txt').readAsStringSync(),
    );
    for (final s in surahs) {
      for (var v = 1; v <= s.verseCount; v++) {
        expect(t.verse(s.number, v), isNotEmpty, reason: '${s.number}:$v');
      }
    }
    expect(t.verse(1, 1), startsWith('In the name of Allah'));
    expect(t.verse(2, 255), startsWith('Allah - there is no deity except Him'));
    expect(t.verse(114, 6), 'From among the jinn and mankind."');
  });
}
