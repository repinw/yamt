import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_picker.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<void> showCalorieGoalStartDialog({
  required BuildContext context,
  required DateTime initialGoalStartAt,
  required Future<bool> Function(DateTime goalStartAt) onSaveGoalStart,
}) async {
  var selectedGoalStartAt = CalorieGoalStartPicker.roundToMinute(
    initialGoalStartAt,
  );
  final l10n = AppLocalizations.of(context)!;

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final locale = Localizations.localeOf(context).toLanguageTag();
          final dateFormat = DateFormat.yMMMd(locale);
          final timeFormat = DateFormat.Hm(locale);

          Future<void> pickDate() async {
            final pickedDate = await CalorieGoalStartPicker.pickDate(
              context,
              initialGoalStartAt: selectedGoalStartAt,
            );
            if (pickedDate == null) {
              return;
            }

            setState(() {
              selectedGoalStartAt = CalorieGoalStartPicker.combineDateAndTime(
                date: pickedDate,
                time: TimeOfDay.fromDateTime(selectedGoalStartAt),
              );
            });
          }

          Future<void> pickTime() async {
            final pickedTime = await CalorieGoalStartPicker.pickTime(
              context,
              initialGoalStartAt: selectedGoalStartAt,
            );
            if (pickedTime == null) {
              return;
            }

            setState(() {
              selectedGoalStartAt = CalorieGoalStartPicker.combineDateAndTime(
                date: selectedGoalStartAt,
                time: pickedTime,
              );
            });
          }

          return AlertDialog(
            title: Text(l10n.caloriesGoalStartDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.caloriesGoalStartDateLabel),
                  subtitle: Text(dateFormat.format(selectedGoalStartAt)),
                  trailing: TextButton(
                    key: CalorieGoalStartDialogKeys.changeDateButton,
                    onPressed: pickDate,
                    child: Text(l10n.caloriesCalculatorGoalStartChangeAction),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.caloriesGoalStartTimeLabel),
                  subtitle: Text(timeFormat.format(selectedGoalStartAt)),
                  trailing: TextButton(
                    key: CalorieGoalStartDialogKeys.changeTimeButton,
                    onPressed: pickTime,
                    child: Text(l10n.caloriesCalculatorGoalStartChangeAction),
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
                key: CalorieGoalStartDialogKeys.saveButton,
                onPressed: () => Navigator.of(dialogContext).pop(true),
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

  final saved = await onSaveGoalStart(selectedGoalStartAt);
  if (!context.mounted || saved) {
    return;
  }

  messenger.showSnackBar(
    SnackBar(content: Text(l10n.caloriesGoalStartSaveFailed)),
  );
}
