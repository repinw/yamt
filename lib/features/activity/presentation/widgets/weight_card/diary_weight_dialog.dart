import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/weight_entry_dialog.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the diary weight dialog, which adds a weighing of [day].
Future<void> showDiaryWeightDialog({
  required BuildContext context,
  required DiaryWeightActions weightActions,
  required DateTime selectedDay,
  required DateTime day,
  required double? initialWeightKg,
  Future<void> Function({required DateTime day, required double weightKg})?
  onWeightSaved,
}) async {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final dayLabel = DateFormat.yMMMd(locale).format(day);
  final l10n = AppLocalizations.of(context)!;
  final weightKg = await showWeightEntryDialog(
    context: context,
    labels: WeightEntryDialogLabels(
      title: l10n.diaryWeightDialogTitle(dayLabel),
      fieldLabel: l10n.caloriesCalculatorWeightLabel,
      emptyErrorText: l10n.caloriesCalculatorWeightEmpty,
      invalidErrorText: l10n.caloriesCalculatorWeightInvalid,
      cancelActionLabel: l10n.inventoryReceiptReviewCancelAction,
      saveActionLabel: l10n.diaryWeightSaveAction,
    ),
    keys: const WeightEntryDialogKeys(
      fieldKey: DiaryWeightDialogKeys.weightDialogField,
      saveButtonKey: DiaryWeightDialogKeys.weightDialogSaveButton,
    ),
    initialWeightKg: initialWeightKg,
  );
  if (!context.mounted || weightKg == null) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context)..hideAppSnackBar();
  final saved = await weightActions.saveManualWeight(
    selectedDay: selectedDay,
    day: day,
    weightKg: weightKg,
  );
  if (!context.mounted) {
    return;
  }
  if (!saved) {
    messenger.showAppSnackBar(
      l10n.diaryWeightSaveFailed,
      tone: AppSnackBarTone.error,
    );
    return;
  }
  await onWeightSaved?.call(day: day, weightKg: weightKg);
}
