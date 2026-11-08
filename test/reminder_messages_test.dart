import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/data/reminder_messages.dart';

void main() {
  test('consecutive days get different sayings', () {
    final a = reminderFor(DateTime(2026, 11, 8, 20));
    final b = reminderFor(DateTime(2026, 11, 9, 20));
    expect(a.body, isNot(b.body));
    // The time of day doesn't change the day's message.
    expect(reminderFor(DateTime(2026, 11, 8, 6)).body, a.body);
  });

  test('mentions a streak worth keeping', () {
    final day = DateTime(2026, 11, 8);
    expect(reminderFor(day, streak: 5).title, 'Keep your 5-day streak going');
    expect(reminderFor(day, streak: 1).title, isNot(contains('streak')));
  });
}
