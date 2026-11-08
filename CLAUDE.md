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

Flutter app for reading the Quran and tracking reading progress (khathm completion). Four tabs with bottom navigation: Read, Tracker, Progress, Settings.

**State management:** Single `TrackerStore` (extends `ChangeNotifier`) holds all reading history, persisted to `SharedPreferences` as JSON. Screens listen via `addListener`/`ListenableBuilder`.

**Data flow:** `TrackerStore` → `List<ReadingEntry>` (ordered by savedAt) → `dailyCounts()` computes verses-per-day from consecutive entries. First entry is baseline only (no verse count attributed).

**Key data:** `surahs.dart` has static metadata for all 114 surahs (number, name, verseCount). `absoluteVerse()` and `totalVerses` convert surah:verse to a linear position for progress calculation.

**Quran text:** `assets/quran/quran-uthmani.txt` is the Tanzil Uthmani text (CC BY 3.0, must stay verbatim, including its copyright block), rendered with the bundled Amiri Quran font (`quranFontFamily`). `data/quran.dart` loads it (`QuranText.load()`) and lifts the Bismillah out of each surah's first verse for display. `data/quran_meta.dart` is generated from Tanzil's `quran-data.js` (Arabic names, Meccan/Medinan, the 604 Madani mushaf page starts, 30 juz starts and 240 hizb-quarter starts); `pageOf`, `juzOf` and `pageSegments` use it. `data/mushaf_layout.dart` is generated from quran.com's line layout of the 1405 AH Madani mushaf (`mushaf=2`): for each page, its 15 lines (8 on pages 1-2) as indexes into `QuranText.tokens` (words plus a verse-end marker per verse), or a surah banner / Bismillah line. `QuranText`'s word splitting (`_displayWords`) must stay in step with that generator. `ReaderStore` persists the last page read.

**Screens:**
- `QuranIndexScreen` (first tab) — continue-reading card, Surah/Juz toggle, searchable surah index. Opens `QuranReaderScreen`.
- `QuranReaderScreen` — `PageView` of the 604 mushaf pages (reversed so pages turn right-to-left), each laid out line for line as printed: text sized to fit the widest line, lines justified and spread over the page height (scrolls instead when too short, e.g. landscape). Styled after a printed mushaf: full-screen paper page with a caption (surah, juz, hizb, page) and engraved surah frames (`_SurahFramePainter`). A tap toggles the top bar; holding a verse offers "Mark as read up to here" (saves to `TrackerStore`) and copy.
- `TrackerScreen` — surah CupertinoPicker (~3 visible items) + verse TextField with +/- stepper buttons (long-press repeats). Shows progress in an Islamic-themed gradient header.
- `ProgressScreen` — daily stats row, bar chart (fl_chart), and swipe-to-delete history list.

**Theming:** `theme.dart` defines full light/dark themes using an emerald green + gold Islamic palette (`AppColors`). `widgets/islamic_patterns.dart` provides decorative elements (8-pointed star pattern painter, gradient header with Bismillah, diamond divider).

## Signing

Android release signing uses `android/key.properties` (gitignored) pointing to `~/upload-keystore.jks`. The keystore alias is `upload`.

## Package

- App ID: `com.khathmulqurantracker`
- Min SDK: 24, Target SDK: 36
- NDK: 27.0.12077973
