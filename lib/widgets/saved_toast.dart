import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../models/streak.dart';
import '../state/tracker_store.dart';
import '../theme.dart';
import 'top_toast.dart';

/// Confirms a position just saved to [tracker], with the reading streak it
/// keeps going.
void showSavedToast(
  BuildContext context,
  TrackerStore tracker,
  int surah,
  int verse,
) {
  final saved = 'Saved ${surahs[surah - 1].name} $surah:$verse';
  final streak = readingStreak(tracker.daily, DateTime.now()).current;
  if (streak == 0) {
    showTopToast(context, saved);
    return;
  }
  showTopToast(
    context,
    streak == 1 ? '$saved · Streak started' : '$saved · $streak-day streak',
    icon: Icons.local_fire_department_rounded,
    // The toast is dark in light mode and light in dark mode.
    iconColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.goldDark
        : AppColors.goldLight,
  );
}
