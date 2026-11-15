import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/data/quran.dart';
import 'package:khathmtracker/screens/inspire_screen.dart';
import 'package:khathmtracker/state/appearance_store.dart';
import 'package:khathmtracker/state/reader_store.dart';
import 'package:khathmtracker/state/tracker_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget inspire({int tab = 0}) => MaterialApp(
    home: Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          InspireScreen(
            reader: ReaderStore(prefs),
            tracker: TrackerStore(prefs),
            appearance: AppearanceStore(prefs),
          ),
          const SizedBox(),
        ],
      ),
    ),
  );

  /// How far each card's bar along the top has filled.
  List<double> bars(WidgetTester tester) => [
    for (final bar in tester.widgetList<LinearProgressIndicator>(
      // Found in a hidden tab too.
      find.byType(LinearProgressIndicator, skipOffstage: false),
    ))
      bar.value!,
  ];

  testWidgets('plays cards like stories', (tester) async {
    await tester.runAsync(QuranText.load);
    await tester.pumpWidget(inspire());
    await tester.pump();
    expect(bars(tester).first, 0);

    // Each card shows for at most 15 seconds, then moves on by itself.
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(milliseconds: 300));
    expect(bars(tester)[0], 1);
    expect(bars(tester)[1], lessThan(0.1));

    // A tap on the left goes back a card.
    await tester.tapAt(
      tester.getTopLeft(find.byType(PageView)) + const Offset(20, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(bars(tester)[0], lessThan(0.1));

    // Holding pauses the card.
    await tester.pump(const Duration(seconds: 2));
    final hold = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await tester.pump(const Duration(seconds: 1));
    final held = bars(tester)[0];
    await tester.pump(const Duration(seconds: 20));
    expect(held, greaterThan(0));
    expect(bars(tester)[0], held);
    await hold.up();
    // A frame to start the timer again, then time for it to finish.
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    await tester.pump(const Duration(milliseconds: 300));
    expect(bars(tester)[0], 1);
  });

  testWidgets('waits while its tab is hidden', (tester) async {
    await tester.runAsync(QuranText.load);
    await tester.pumpWidget(inspire(tab: 1));
    await tester.pump(const Duration(seconds: 30));
    expect(bars(tester).first, 0);
  });
}
