import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_quick_entry_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_framed_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_label_input_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_label_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The nutrition label of the quick entry page: the calories and the macros
/// of the whole eaten amount as inputs. Only the calories are required.
class DiaryQuickEntryLabel extends StatelessWidget {
  /// Creates the label.
  const new({
    required this.texts,
    required this.focusNodes,
    required this.onChanged,
    required this.onSubmitted,
    super.key,
  });

  /// Key of the input of [value].
  static Key valueKey(DiaryQuickEntryValue value) {
    return Key('diary_quick_entry_${value.name}_field');
  }

  /// Text of each input.
  final Map<DiaryQuickEntryValue, TextEditingController> texts;

  /// Focus of each input.
  final Map<DiaryQuickEntryValue, FocusNode> focusNodes;

  /// Called when an input changes.
  final void Function(DiaryQuickEntryValue value, String text) onChanged;

  /// Called when an input is confirmed on the keyboard.
  final ValueChanged<DiaryQuickEntryValue> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final macros = MetricAccentColors.of(context);
    const values = DiaryQuickEntryValue.values;

    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EatLabelTitle(
            text: l10n.eatPageNutritionTitle,
            trailing: [
              Text(
                l10n.diaryQuickEntryValuesHeader,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: AppFonts.mono,
                  fontWeight: FontWeight.w500,
                  color: colors.muted,
                ),
              ),
            ],
          ),
          for (final (index, value) in values.indexed)
            EatLabelInputRow(
              fieldKey: valueKey(value),
              label: switch (value) {
                DiaryQuickEntryValue.kcal => l10n.diaryQuickEntryKcalLabel,
                DiaryQuickEntryValue.fat => l10n.caloriesFatLabel,
                DiaryQuickEntryValue.carbs => l10n.caloriesCarbsLabel,
                DiaryQuickEntryValue.protein => l10n.caloriesProteinLabel,
              },
              unit: value == DiaryQuickEntryValue.kcal
                  ? l10n.caloriesUnitKcal
                  : l10n.caloriesUnitGram,
              accent: switch (value) {
                DiaryQuickEntryValue.kcal => null,
                DiaryQuickEntryValue.fat => macros.fat,
                DiaryQuickEntryValue.carbs => macros.carbs,
                DiaryQuickEntryValue.protein => macros.protein,
              },
              isRequired: value == DiaryQuickEntryValue.kcal,
              controller: texts[value]!,
              focusNode: focusNodes[value]!,
              bottom: switch (index) {
                0 => BorderSide(
                  color: colors.ink,
                  width: AppFoodLabel.labelEnergyRule,
                ),
                _ when index == values.length - 1 => BorderSide.none,
                _ => BorderSide(color: colors.ink),
              },
              onChanged: (text) => onChanged(value, text),
              onSubmitted: () => onSubmitted(value),
            ),
        ],
      ),
    );
  }
}
