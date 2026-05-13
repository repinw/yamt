import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calorie_goal/presentation/widgets/calorie_goal_start_picker.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines save calorie goal start typedef.
typedef SaveCalorieGoalStart = Future<bool> Function(DateTime goalStartDate);

/// Show calorie goal start dialog.
Future<void> showCalorieGoalStartDialog({
  required BuildContext context,
  required DateTime initialGoalStartDate,
  required SaveCalorieGoalStart onSaveGoalStart,
  String? title,
}) async {
  var selectedGoalStartDate = CalorieGoalStartPicker.normalizeDate(
    initialGoalStartDate,
  );
  final l10n = AppLocalizations.of(context)!;

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final locale = Localizations.localeOf(context).toLanguageTag();
          final dateFormat = DateFormat.yMMMd(locale);

          Future<void> pickDate() async {
            final pickedDate = await CalorieGoalStartPicker.pickDate(
              context,
              initialGoalStartDate: selectedGoalStartDate,
            );
            if (pickedDate == null) {
              return;
            }

            setState(() {
              selectedGoalStartDate = pickedDate;
            });
          }

          return AlertDialog(
            title: Text(title ?? l10n.caloriesGoalStartDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.caloriesGoalStartDateLabel),
                  subtitle: Text(dateFormat.format(selectedGoalStartDate)),
                  trailing: TextButton(
                    key: CalorieGoalStartDialogKeys.changeDateButton,
                    onPressed: pickDate,
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

  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

  final saved = await onSaveGoalStart(selectedGoalStartDate);
  if (!context.mounted || saved) {
    return;
  }

  messenger.showSnackBar(
    SnackBar(content: Text(l10n.caloriesGoalStartSaveFailed)),
  );
}
