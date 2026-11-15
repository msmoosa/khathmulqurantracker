import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khathmtracker/widgets/no_bold_text.dart';

void main() {
  testWidgets('Quran text ignores the system bold text setting', (
    tester,
  ) async {
    bool? inside;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(boldText: true),
        child: NoBoldText(
          child: Builder(
            builder: (context) {
              inside = MediaQuery.boldTextOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(inside, isFalse);
  });
}
