import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/data/mushaf_layout.dart';
import 'package:khathmtracker/data/quran.dart';
import 'package:khathmtracker/data/quran_meta.dart';
import 'package:khathmtracker/main.dart';
import 'package:khathmtracker/state/reader_store.dart';
import 'package:khathmtracker/state/reminder_service.dart';
import 'package:khathmtracker/state/tracker_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('metadata covers the Madani mushaf', () {
    expect(surahArabicNames.length, 114);
    expect(pageStarts.length ~/ 2, mushafPageCount);
    expect(juzStarts.length ~/ 2, 30);
  });

  test('maps verses to pages and juz', () {
    expect(pageOf(1, 1), 1);
    expect(pageOf(1, 7), 1);
    expect(pageOf(2, 1), 2);
    expect(pageOf(2, 255), 42);
    expect(pageOf(114, 6), 604);
    expect(juzOf(2, 141), 1);
    expect(juzOf(2, 142), 2);
    expect(juzOf(78, 1), 30);
    expect(hizbLabel(1, 1), '1');
    expect(hizbLabel(3, 1), '5 ¾');
    expect(hizbLabel(114, 6), '60 ¾');
  });

  test('every verse appears on exactly one page', () {
    var count = 0;
    var previous = 0;
    for (var page = 1; page <= mushafPageCount; page++) {
      for (final s in pageSegments(page)) {
        for (var v = s.firstVerse; v <= s.lastVerse; v++) {
          final abs = VerseRef(s.surah, v).absolute;
          expect(abs, previous + 1);
          previous = abs;
          count++;
        }
      }
    }
    expect(count, 6236);
    // The last page holds the final three surahs.
    expect(pageSegments(604).map((s) => s.surah), [112, 113, 114]);
  });

  test('parses the Uthmani text and lifts out the Bismillah', () {
    final text = QuranText.parse(
      File('assets/quran/quran-uthmani.txt').readAsStringSync(),
    );
    expect(text.bismillah, startsWith('بِسْمِ'));
    expect(text.verse(1, 1), text.bismillah);
    expect(text.verse(2, 1), 'الٓمٓ');
    // At-Tawbah has no Bismillah, so its first verse is left whole.
    expect(text.verse(9, 1).split(' '), hasLength(9));
    // The Bismillah inside An-Naml 30 is part of the verse and stays.
    expect(text.verse(27, 30), contains('بِسْمِ'));
    expect(text.verse(114, 6), isNotEmpty);
  });

  test('the line layout lines up with the text, page for page', () {
    final text = QuranText.parse(
      File('assets/quran/quran-uthmani.txt').readAsStringSync(),
    );
    expect(text.tokens, hasLength(mushafTokenCount));
    expect(mushafLines, hasLength(mushafPageCount));
    var previous = -1;
    for (var page = 1; page <= mushafPageCount; page++) {
      final lines = mushafLines[page - 1];
      expect(lines, hasLength(page <= 2 ? 8 : 15));
      final textLines = lines.where((l) => l >= 0).toList();
      // Each page opens on its first verse, and lines run in order.
      expect(text.tokens[textLines.first].ref, pageStart(page));
      for (final l in textLines) {
        expect(l, greaterThan(previous));
        previous = l;
      }
      // Banners name the surah that starts right after them.
      for (final l in lines.where((l) => l < 0 && l != bismillahLine)) {
        expect(
          pageSegments(page).map((s) => s.surah).toList()
            ..addAll(page < mushafPageCount ? [pageStart(page + 1).surah] : []),
          contains(-l),
        );
      }
    }
    // A verse-end marker never starts a page.
    expect(text.tokens.first.text, isNot(startsWith('\u06DD')));
  });

  test('formats Arabic-Indic numbers', () {
    expect(arabicNumber(7), '٧');
    expect(arabicNumber(286), '٢٨٦');
  });

  testWidgets('opens a surah from the index and remembers the page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'reminder_permission_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final reader = ReaderStore(prefs);
    final tracker = TrackerStore(prefs);
    await tester.pumpWidget(
      KhathmTrackerApp(
        store: tracker,
        reminders: ReminderService(prefs),
        reader: reader,
      ),
    );

    expect(find.text('Al-Fatihah'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'baqarah');
    await tester.pump();
    expect(find.text('Al-Fatihah'), findsNothing);

    await tester.runAsync(() => QuranText.load());
    await tester.tap(find.text('Al-Baqarah'));
    await tester.pumpAndSettle();

    expect(find.text('Al-Baqarah, Juz 1, Hizb 1, Page 2'), findsOneWidget);
    expect(find.text('سُورَةُ البقرة'), findsOneWidget);
    expect(reader.lastPage, 2);

    // Holding a word offers to save that verse to the tracker.
    await tester.longPress(find.text('ٱلْكِتَـٰبُ'));
    await tester.pumpAndSettle();
    expect(find.text('Al-Baqarah · Verse 2'), findsOneWidget);
    await tester.tap(find.text('Mark as read up to here'));
    await tester.pumpAndSettle();
    expect(tracker.lastEntry?.verse, 2);
  });
}
