const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// e.g. "17 Oct"
String formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// e.g. "17 Oct, 14:05"
String formatDateTime(DateTime d) =>
    '${formatDay(d)}, ${_two(d.hour)}:${_two(d.minute)}';
