import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';

import '../state/reminder_service.dart';

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.khathmulqurantracker';

const _appStoreId = '6826256750';
const _appStoreUrl = 'https://apps.apple.com/app/id$_appStoreId';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.reminders});

  final ReminderService reminders;

  Future<void> _rate() async {
    await InAppReview.instance.openStoreListing(appStoreId: _appStoreId);
  }

  Future<void> _share(BuildContext context) async {
    // iPad needs an anchor for the share sheet popover.
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Khathmul Quran Tracker',
        text:
            'I track my Quran reading with Khathmul Quran Tracker.\n\n'
            'iPhone: $_appStoreUrl\n'
            'Android: $_playStoreUrl',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(
    text,
    style: theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  Future<void> _toggle(BuildContext context, bool value) async {
    if (value) {
      final granted = await reminders.requestPermission();
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications are turned off for this app. '
                'Enable them in your device settings.',
              ),
            ),
          );
        return;
      }
    }
    await reminders.setEnabled(value);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminders.time,
      helpText: 'Reminder time',
    );
    if (picked != null) await reminders.setTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: reminders,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel(theme, 'Reminders'),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ReminderService.isSupported
                  ? Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications_outlined),
                          title: const Text('Daily reminder'),
                          subtitle: const Text(
                            'A notification to recite Quran',
                          ),
                          value: reminders.enabled,
                          onChanged: (v) => _toggle(context, v),
                        ),
                        const Divider(height: 0.5, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.schedule_rounded),
                          title: const Text('Reminder time'),
                          enabled: reminders.enabled,
                          trailing: Text(
                            reminders.time.format(context),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: reminders.enabled
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => _pickTime(context),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Daily reminders are available in the iOS and '
                        'Android apps.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(theme, 'About'),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (!kIsWeb) ...[
                    ListTile(
                      leading: const Icon(Icons.star_outline_rounded),
                      title: const Text('Rate the app'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _rate,
                    ),
                    const Divider(height: 0.5, indent: 16, endIndent: 16),
                  ],
                  Builder(
                    builder: (context) => ListTile(
                      leading: const Icon(Icons.ios_share_rounded),
                      title: const Text('Share this app'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _share(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
