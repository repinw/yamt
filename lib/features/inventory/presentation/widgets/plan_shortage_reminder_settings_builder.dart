import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/presentation/controllers/plan_shortage_reminder_controller.dart';

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
  /// in minutes after midnight, and their setters.
  final Widget Function(
    BuildContext context, {
    required bool enabled,
    required int minuteOfDay,
    required ValueChanged<bool> setEnabled,
    required ValueChanged<int> setMinuteOfDay,
  })
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(planShortageReminderControllerProvider);
    return builder(
      context,
      enabled: settings.enabled,
      minuteOfDay: settings.minuteOfDay,
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
    );
  }
}
