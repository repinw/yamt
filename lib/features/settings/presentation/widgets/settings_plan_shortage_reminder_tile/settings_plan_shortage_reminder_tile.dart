import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/presentation/widgets/plan_shortage_reminder_settings_builder.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row turning the day-before reminder for missing plan
/// ingredients on or off.
///
/// The reminder is owned by the Inventory feature; this row only renders it
/// through `PlanShortageReminderSettingsBuilder`.
class SettingsPlanShortageReminderTile extends StatelessWidget {
  /// Creates the reminder switch row.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlanShortageReminderSettingsBuilder(
      builder:
          (
            context, {
            required enabled,
            required minuteOfDay,
            required setEnabled,
            required setMinuteOfDay,
          }) => SettingsTile(
            key: SettingsPageKeys.planShortageReminderTile,
            icon: Icons.notifications_none_rounded,
            title: l10n.settingsPlanShortageReminderTitle,
            subtitle: l10n.settingsPlanShortageReminderSubtitle,
            showChevron: false,
            trailing: Switch(value: enabled, onChanged: setEnabled),
            onTap: () => setEnabled(!enabled),
          ),
    );
  }
}

/// Settings row picking the time of the day-before reminder.
class SettingsPlanShortageReminderTimeTile extends StatelessWidget {
  /// Creates the reminder time row.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlanShortageReminderSettingsBuilder(
      builder:
          (
            context, {
            required enabled,
            required minuteOfDay,
            required setEnabled,
            required setMinuteOfDay,
          }) {
            final time = TimeOfDay(
              hour: minuteOfDay ~/ 60,
              minute: minuteOfDay % 60,
            );
            return SettingsTile(
              key: SettingsPageKeys.planShortageReminderTimeTile,
              icon: Icons.schedule_rounded,
              title: l10n.settingsPlanShortageReminderTimeTitle,
              subtitle: MaterialLocalizations.of(context).formatTimeOfDay(
                time,
                alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                  context,
                ),
              ),
              enabled: enabled,
              onTap: () => unawaited(
                showTimePicker(context: context, initialTime: time).then((
                  picked,
                ) {
                  if (picked != null) {
                    setMinuteOfDay(picked.hour * 60 + picked.minute);
                  }
                }),
              ),
            );
          },
    );
  }
}
