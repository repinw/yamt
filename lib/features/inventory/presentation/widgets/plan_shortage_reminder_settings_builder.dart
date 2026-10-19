import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/presentation/controllers/plan_shortage_reminder_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Builds the controls of the day-before reminder for missing plan
/// ingredients.
///
/// Public edge for surfaces owned by other features (the Settings sheet):
/// they get the current values and the setters without reaching into the
/// controller.
class PlanShortageReminderSettingsBuilder extends ConsumerWidget {
  /// Creates the settings builder.
  const new({required this.builder, super.key});

  /// Builds the controls from whether the reminder is on, its time of day
  /// in minutes after midnight, whether the system blocks its notifications
  /// while it is on, and the setters.
  final Widget Function(
    BuildContext context, {
    required bool enabled,
    required int minuteOfDay,
    required bool blocked,
    required ValueChanged<bool> setEnabled,
    required ValueChanged<int> setMinuteOfDay,
    required VoidCallback openSystemSettings,
  })
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(planShortageReminderControllerProvider);
    return builder(
      context,
      enabled: settings.enabled,
      minuteOfDay: settings.minuteOfDay,
      blocked: ref.watch(planShortageReminderBlockedProvider),
      setEnabled: (enabled) => unawaited(
        ref
            .read(planShortageReminderControllerProvider.notifier)
            .setEnabled(enabled: enabled),
      ),
      setMinuteOfDay: (minute) => unawaited(
        ref
            .read(planShortageReminderControllerProvider.notifier)
            .setMinuteOfDay(minute),
      ),
      openSystemSettings: () async {
        final opened = await ref
            .read(planShortageReminderControllerProvider.notifier)
            .openSystemSettings();
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showAppSnackBar(
            AppLocalizations.of(context)!.planShortageReminderSettingsFailed,
            tone: AppSnackBarTone.error,
          );
        }
      },
    );
  }
}
