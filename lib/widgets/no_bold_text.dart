import 'package:flutter/widgets.dart';

/// Keeps the system's bold text setting off [child], so Quran text keeps
/// its true letterforms; the rest of the app still follows the setting.
class NoBoldText extends StatelessWidget {
  const NoBoldText({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(boldText: false),
      child: child,
    );
  }
}
