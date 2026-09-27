import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_framed_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_label_title.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_nutrient_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The nutrition label of the product editor: the rows of a printed food
/// label with an input per 100 g, and a row that adds the optional
/// nutrients.
class ManualProductNutritionEditor extends StatelessWidget {
  /// Creates the label.
  const new({
    required this.texts,
    required this.focusNodes,
    required this.per100Header,
    required this.showPolyunsaturatedFat,
    required this.showFiber,
    required this.onFieldChanged,
    required this.onFieldSubmitted,
    required this.onAddOptionalNutrition,
    super.key,
  });

  /// Key of the button that adds an optional nutrient.
  static const addKey = Key(
    'receipt_review_manual_add_optional_nutrition_button',
  );

  /// Text of each input.
  final Map<ManualProductFormField, TextEditingController> texts;

  /// Focus of each input.
  final Map<ManualProductFormField, FocusNode> focusNodes;

  /// Header of the value column, such as "Per 100 g".
  final String per100Header;

  /// Whether the polyunsaturated fat row is shown.
  final bool showPolyunsaturatedFat;

  /// Whether the fiber row is shown.
  final bool showFiber;

  /// Called when an input changes.
  final void Function(ManualProductFormField field, String text) onFieldChanged;

  /// Called when an input is confirmed on the keyboard.
  final ValueChanged<ManualProductFormField> onFieldSubmitted;

  /// Shows the row of an optional nutrient.
  final ValueChanged<InventoryReceiptOptionalNutritionType>
  onAddOptionalNutrition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final macros = MetricAccentColors.of(context);
    final rows = <ManualProductNutrientLine>[
      (
        field: ManualProductFormField.kcal,
        label: l10n.caloriesNutritionTableEnergy,
        unit: l10n.caloriesUnitKcal,
        accent: null,
        isPart: false,
      ),
      (
        field: ManualProductFormField.fat,
        label: l10n.caloriesFatLabel,
        unit: l10n.caloriesUnitGram,
        accent: macros.fat,
        isPart: false,
      ),
      _part(ManualProductFormField.saturatedFat, l10n, isPart: true),
      if (showPolyunsaturatedFat)
        _part(ManualProductFormField.polyunsaturatedFat, l10n, isPart: true),
      (
        field: ManualProductFormField.carbs,
        label: l10n.caloriesCarbsLabel,
        unit: l10n.caloriesUnitGram,
        accent: macros.carbs,
        isPart: false,
      ),
      _part(ManualProductFormField.sugar, l10n, isPart: true),
      if (showFiber) _part(ManualProductFormField.fiber, l10n, isPart: false),
      (
        field: ManualProductFormField.protein,
        label: l10n.caloriesProteinLabel,
        unit: l10n.caloriesUnitGram,
        accent: macros.protein,
        isPart: false,
      ),
      _part(ManualProductFormField.salt, l10n, isPart: false),
    ];
    final optionalTypes = [
      if (!showPolyunsaturatedFat)
        InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
      if (!showFiber) InventoryReceiptOptionalNutritionType.fiber,
    ];

    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EatLabelTitle(text: l10n.eatPageNutritionTitle),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              per100Header,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: AppFonts.mono,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ),
          for (final (index, row) in rows.indexed)
            ManualProductNutrientRow(
              row: row,
              controller: texts[row.field]!,
              focusNode: focusNodes[row.field]!,
              bottom: _bottomRule(colors, rows, index, optionalTypes),
              onChanged: (text) => onFieldChanged(row.field, text),
              onSubmitted: () => onFieldSubmitted(row.field),
            ),
          if (optionalTypes.isNotEmpty)
            _AddNutrientButton(
              types: optionalTypes,
              onSelected: onAddOptionalNutrition,
            ),
        ],
      ),
    );
  }

  static ManualProductNutrientLine _part(
    ManualProductFormField field,
    AppLocalizations l10n, {
    required bool isPart,
  }) {
    return (
      field: field,
      label: switch (field) {
        ManualProductFormField.saturatedFat =>
          l10n.caloriesNutritionTableSaturatedFat,
        ManualProductFormField.polyunsaturatedFat =>
          l10n.caloriesNutritionTablePolyunsaturatedFat,
        ManualProductFormField.sugar => l10n.caloriesNutritionTableSugar,
        ManualProductFormField.fiber => l10n.caloriesNutritionTableFiber,
        _ => l10n.caloriesNutritionTableSalt,
      },
      unit: l10n.caloriesUnitGram,
      accent: null,
      isPart: isPart,
    );
  }

  static BorderSide _bottomRule(
    FoodLabelColors colors,
    List<ManualProductNutrientLine> rows,
    int index,
    List<InventoryReceiptOptionalNutritionType> optionalTypes,
  ) {
    if (index == rows.length - 1) {
      return optionalTypes.isEmpty
          ? BorderSide.none
          : BorderSide(color: colors.rule);
    }
    if (index == 0) {
      return BorderSide(color: colors.ink, width: AppFoodLabel.labelEnergyRule);
    }
    if (rows[index + 1].isPart) {
      return BorderSide(color: colors.rule);
    }
    return BorderSide(color: colors.ink);
  }
}

class _AddNutrientButton extends StatelessWidget {
  const new({required this.types, required this.onSelected});

  final List<InventoryReceiptOptionalNutritionType> types;
  final ValueChanged<InventoryReceiptOptionalNutritionType> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: colors.muted);

    return PopupMenuButton<InventoryReceiptOptionalNutritionType>(
      key: ManualProductNutritionEditor.addKey,
      tooltip: l10n.inventoryReceiptReviewManualAddNutritionAction,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final type in types)
          PopupMenuItem(
            value: type,
            child: Text(switch (type) {
              InventoryReceiptOptionalNutritionType.polyunsaturatedFat =>
                l10n.caloriesNutritionTablePolyunsaturatedFat,
              InventoryReceiptOptionalNutritionType.fiber =>
                l10n.caloriesNutritionTableFiber,
            }),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            Icon(Icons.add_rounded, color: colors.muted),
            Flexible(
              child: Text(
                l10n.inventoryReceiptReviewManualAddNutritionAction,
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
