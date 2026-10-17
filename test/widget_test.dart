import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/main.dart';
import 'package:khathmtracker/state/tracker_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('saves a position and resets back to it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = TrackerStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(KhathmTrackerApp(store: store));

    expect(find.text('No position saved yet'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // Let the "Saved" snackbar clear so it doesn't cover the buttons.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(store.lastEntry?.surah, 1);
    expect(store.lastEntry?.verse, 1);

    // Scroll the verse wheel forward a few items; Reset should restore 1:1.
    await tester.drag(find.text('1').last, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verse 1 of'), findsNothing);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Surah 1 · Verse 1 of 7'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.textContaining('· starting point'), findsOneWidget);
  });
}
