import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/main.dart';
import 'package:khathmtracker/state/reminder_service.dart';
import 'package:khathmtracker/state/tracker_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders at a typical phone size so lazily built lists are on screen.
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

bool _isEnabled(WidgetTester tester, String label) => tester
    .widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    )
    .enabled;

void main() {
  late TrackerStore store;
  late ReminderService reminders;

  setUp(() async {
    // Skip the first-launch permission dialog; the plugin isn't available.
    SharedPreferences.setMockInitialValues({
      'reminder_permission_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    store = TrackerStore(prefs);
    reminders = ReminderService(prefs);
  });

  testWidgets('saves a position and resets back to it', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      KhathmTrackerApp(store: store, reminders: reminders),
    );

    expect(find.text('Verse / 7'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // Let the "Saved" snackbar clear so it doesn't cover the buttons.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(store.lastEntry?.surah, 1);
    expect(store.lastEntry?.verse, 1);
    expect(_isEnabled(tester, 'Save'), isFalse);

    // Scroll the verse wheel forward a few items; Reset should restore 1:1.
    await tester.drag(find.text('1').last, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(_isEnabled(tester, 'Save'), isTrue);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(_isEnabled(tester, 'Save'), isFalse);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.textContaining('· starting point'), findsOneWidget);
  });

  testWidgets('settings shows the default 8 PM reminder', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      KhathmTrackerApp(store: store, reminders: reminders),
    );

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.text('8:00 PM'), findsOneWidget);
  });
}
