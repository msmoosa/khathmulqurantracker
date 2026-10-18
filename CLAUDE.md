# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

- **Run (debug):** `flutter run` — select target device when prompted
- **Analyze:** `flutter analyze` — static analysis with flutter_lints
- **Build Android release:** `flutter build appbundle --release` — outputs to `build/app/outputs/bundle/release/app-release.aab`
- **Build web:** `flutter build web --release` — outputs to `build/web/`
- **Deploy web:** `vercel build/web --prod --name kqt --yes` — deploys to kqt.vercel.app
- **Regenerate app icons:** `dart run flutter_launcher_icons`

## Architecture

Flutter app for tracking Quran reading progress (khathm completion). Two-screen app with bottom navigation.

**State management:** Single `TrackerStore` (extends `ChangeNotifier`) holds all reading history, persisted to `SharedPreferences` as JSON. Screens listen via `addListener`/`ListenableBuilder`.

**Data flow:** `TrackerStore` → `List<ReadingEntry>` (ordered by savedAt) → `dailyCounts()` computes verses-per-day from consecutive entries. First entry is baseline only (no verse count attributed).

**Key data:** `surahs.dart` has static metadata for all 114 surahs (number, name, verseCount). `absoluteVerse()` and `totalVerses` convert surah:verse to a linear position for progress calculation.

**Screens:**
- `TrackerScreen` — surah CupertinoPicker (~3 visible items) + verse TextField with +/- stepper buttons (long-press repeats). Shows progress in an Islamic-themed gradient header.
- `ProgressScreen` — daily stats row, bar chart (fl_chart), and swipe-to-delete history list.

**Theming:** `theme.dart` defines full light/dark themes using an emerald green + gold Islamic palette (`AppColors`). `widgets/islamic_patterns.dart` provides decorative elements (8-pointed star pattern painter, gradient header with Bismillah, diamond divider).

## Signing

Android release signing uses `android/key.properties` (gitignored) pointing to `~/upload-keystore.jks`. The keystore alias is `upload`.

## Package

- App ID: `com.khathmulqurantracker`
- Min SDK: 24, Target SDK: 36
- NDK: 27.0.12077973
