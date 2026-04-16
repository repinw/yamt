import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines save calorie eating window typedef.
typedef SaveCalorieEatingWindow =
    Future<bool> Function(int startMinuteOfDay, int endMinuteOfDay);

/// Show calorie eating window dialog.
Future<void> showCalorieEatingWindowDialog({
  required BuildContext context,
  required int initialStartMinuteOfDay,
  required int initialEndMinuteOfDay,
  required SaveCalorieEatingWindow onSaveEatingWindow,
}) async {
  var selectedStartMinuteOfDay = initialStartMinuteOfDay;
  var selectedEndMinuteOfDay = initialEndMinuteOfDay;
  final l10n = AppLocalizations.of(context)!;

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isValid = isValidEatingWindowMinutes(
            startMinuteOfDay: selectedStartMinuteOfDay,
            endMinuteOfDay: selectedEndMinuteOfDay,
          );

          Future<void> pickStart() async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: timeOfDayFromMinuteOfDay(selectedStartMinuteOfDay),
            );
            if (pickedTime == null || !context.mounted) {
              return;
            }

            setState(() {
              selectedStartMinuteOfDay = minuteOfDayFromTimeOfDay(pickedTime);
            });
          }

          Future<void> pickEnd() async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: timeOfDayFromMinuteOfDay(selectedEndMinuteOfDay),
            );
            if (pickedTime == null || !context.mounted) {
              return;
            }

            setState(() {
              selectedEndMinuteOfDay = minuteOfDayFromTimeOfDay(pickedTime);
            });
          }

          return AlertDialog(
            title: Text(l10n.caloriesEatingWindowDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.caloriesEatingWindowStartLabel),
                  subtitle: Text(
                    formatMinuteOfDay(
                      context,
                      minuteOfDay: selectedStartMinuteOfDay,
                    ),
                  ),
                  trailing: TextButton(
                    key: CalorieEatingWindowDialogKeys.changeStartButton,
                    onPressed: pickStart,
                    child: Text(l10n.caloriesCalculatorGoalStartChangeAction),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.caloriesEatingWindowEndLabel),
                  subtitle: Text(
                    formatMinuteOfDay(
                      context,
                      minuteOfDay: selectedEndMinuteOfDay,
                    ),
                  ),
                  trailing: TextButton(
                    key: CalorieEatingWindowDialogKeys.changeEndButton,
                    onPressed: pickEnd,
                    child: Text(l10n.caloriesCalculatorGoalStartChangeAction),
                  ),
                ),
                if (!isValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.caloriesEatingWindowInvalidRange,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.inventoryReceiptReviewCancelAction),
              ),
              FilledButton(
                key: CalorieEatingWindowDialogKeys.saveButton,
                onPressed: isValid
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: Text(l10n.inventoryReceiptReviewSaveAction),
              ),
            ],
          );
        },
      );
    },
  );

  if (!context.mounted || shouldSave != true) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  final saved = await onSaveEatingWindow(
    selectedStartMinuteOfDay,
    selectedEndMinuteOfDay,
  );
  if (!context.mounted || saved) {
    return;
  }

  messenger.showSnackBar(
    SnackBar(content: Text(l10n.caloriesEatingWindowSaveFailed)),
  );
}

/// Format eating window label.
String formatEatingWindowLabel(
  BuildContext context, {
  required int startMinuteOfDay,
  required int endMinuteOfDay,
}) {
  final start = formatMinuteOfDay(context, minuteOfDay: startMinuteOfDay);
  final end = formatMinuteOfDay(context, minuteOfDay: endMinuteOfDay);
  return '$start - $end';
}

/// Format minute of day.
String formatMinuteOfDay(BuildContext context, {required int minuteOfDay}) {
  final time = timeOfDayFromMinuteOfDay(minuteOfDay);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    time,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// Time of day from minute of day.
TimeOfDay timeOfDayFromMinuteOfDay(int minuteOfDay) {
  final normalizedMinute = minuteOfDay.clamp(0, (24 * 60) - 1);
  return TimeOfDay(hour: normalizedMinute ~/ 60, minute: normalizedMinute % 60);
}

/// Minute of day from time of day.
int minuteOfDayFromTimeOfDay(TimeOfDay time) {
  return (time.hour * 60) + time.minute;
}
