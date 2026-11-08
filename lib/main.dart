import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo/demo_data.dart';
import 'screens/progress_screen.dart';
import 'screens/quran_index_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tracker_screen.dart';
import 'state/appearance_store.dart';
import 'state/reader_store.dart';
import 'state/reminder_service.dart';
import 'state/tracker_store.dart';
import 'theme.dart';
import 'widgets/islamic_patterns.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final reminders = ReminderService(prefs);
  final TrackerStore store = kDemoMode
      ? TrackerStore(
          prefs,
          key: 'demo_reading_entries',
          seed: demoEntries(DateTime.now()),
        )
      : TrackerStore(prefs);
  reminders.watch(store);
  runApp(
    KhathmTrackerApp(
      store: store,
      reminders: reminders,
      reader: ReaderStore(prefs),
      appearance: AppearanceStore(prefs),
    ),
  );
  // Set up reminders after the first frame so a slow or failing plugin call
  // can never leave the app stuck on the launch screen.
  reminders.init().catchError((Object e) {
    debugPrint('Reminder setup failed: $e');
  });
}

class KhathmTrackerApp extends StatelessWidget {
  const KhathmTrackerApp({
    super.key,
    required this.store,
    required this.reminders,
    required this.reader,
    required this.appearance,
  });

  final TrackerStore store;
  final ReminderService reminders;
  final ReaderStore reader;
  final AppearanceStore appearance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appearance,
      builder: (context, _) => MaterialApp(
        title: 'Khathmul Quran Tracker',
        debugShowCheckedModeBanner: false,
        theme: lightTheme(),
        darkTheme: darkTheme(),
        themeMode: appearance.themeMode,
        home: HomeShell(
          store: store,
          reminders: reminders,
          reader: reader,
          appearance: appearance,
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.store,
    required this.reminders,
    required this.reader,
    required this.appearance,
  });

  final TrackerStore store;
  final ReminderService reminders;
  final ReaderStore reader;
  final AppearanceStore appearance;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _titles = [
    'Quran',
    'Khathmul Quran Tracker',
    'Progress',
    'Settings',
  ];

  int _tab = kDemoTab;

  @override
  void initState() {
    super.initState();
    if (ReminderService.isSupported &&
        !kDemoMode &&
        !widget.reminders.hasPrompted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askForReminder());
    }
  }

  /// Explains the daily reminder before showing the system permission prompt.
  Future<void> _askForReminder() async {
    final reminders = widget.reminders;
    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: const Text('Daily reminder'),
        content: Text(
          'Khathmul Quran Tracker can remind you every day at '
          '${reminders.time.format(context)} to recite the Quran.\n\n'
          'To do this, the app needs permission to send you notifications. '
          'You can change the time or turn the reminder off at any time '
          'in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow notifications'),
          ),
        ],
      ),
    );
    if (allow != true) {
      await reminders.declinePrompt();
      return;
    }
    final granted = await reminders.requestPermission();
    await reminders.setEnabled(granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(
          context,
        ).appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
        // White status bar icons over the green background.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: const IslamicAppBarBackground(),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            QuranIndexScreen(reader: widget.reader, tracker: widget.store),
            TrackerScreen(store: widget.store, reader: widget.reader),
            ProgressScreen(store: widget.store),
            SettingsScreen(
              reminders: widget.reminders,
              appearance: widget.appearance,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories),
              label: 'Read',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Tracker',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
