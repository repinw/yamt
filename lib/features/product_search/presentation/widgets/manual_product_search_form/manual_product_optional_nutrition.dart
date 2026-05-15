import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart'
    as models;
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_input.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Add button row for optional nutrition.
class OptionalNutritionAddRow extends StatelessWidget {
  /// Creates optional nutrition add row.
  const OptionalNutritionAddRow({
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Row label.
  final String label;

  /// Add action.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        IconButton.outlined(
          key: const Key('receipt_review_manual_add_optional_nutrition_button'),
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          tooltip: label,
        ),
      ],
    );
  }
}

/// Inline composer for optional nutrition fields.
class OptionalNutritionComposer extends StatelessWidget {
  /// Creates optional nutrition composer.
  const OptionalNutritionComposer({
    required this.valueText,
    required this.selectedUnit,
    required this.selectedType,
    required this.availableTypes,
    required this.onValueChanged,
    required this.onUnitChanged,
    required this.onTypeChanged,
    required this.onApply,
    required this.onCancel,
    super.key,
  });

  /// Current value text.
  final String valueText;

  /// Selected nutrition unit.
  final InventoryAmountUnit selectedUnit;

  /// Selected nutrition type.
  final models.InventoryReceiptOptionalNutritionType? selectedType;

  /// Available nutrition types.
  final List<models.InventoryReceiptOptionalNutritionType> availableTypes;

  /// Called when value changes.
  final ValueChanged<String?> onValueChanged;

  /// Called when unit changes.
  final ValueChanged<InventoryAmountUnit?> onUnitChanged;

  /// Called when type changes.
  final ValueChanged<models.InventoryReceiptOptionalNutritionType?>
  onTypeChanged;

  /// Apply action.
  final VoidCallback onApply;

  /// Cancel action.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canApply =
        parseManualProductDouble(valueText) != null && selectedType != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ManualProductTextField(
          name: ManualProductSearchFormFieldName.optionalNutritionValue,
          initialValue: valueText,
          label: l10n.inventoryReceiptReviewManualNutritionValueLabel,
          fieldKey: const Key(
            'receipt_review_manual_optional_nutrition_value_field',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: manualProductNumericInputFormatters,
          onChanged: onValueChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormBuilderDropdown<InventoryAmountUnit>(
                key: const Key(
                  'receipt_review_manual_optional_nutrition_unit_field',
                ),
                name: ManualProductSearchFormFieldName.optionalNutritionUnit,
                initialValue: selectedUnit,
                decoration: InputDecoration(
                  labelText:
                      l10n.inventoryReceiptReviewManualNutritionUnitLabel,
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<InventoryAmountUnit>(
                    value: InventoryAmountUnit.gram,
                    child: Text('g'),
                  ),
                  DropdownMenuItem<InventoryAmountUnit>(
                    value: InventoryAmountUnit.milliliter,
                    child: Text('ml'),
                  ),
                ],
                onChanged: onUnitChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child:
                  FormBuilderDropdown<
                    models.InventoryReceiptOptionalNutritionType
                  >(
                    key: const Key(
                      'receipt_review_manual_optional_nutrition_type_field',
                    ),
                    name:
                        ManualProductSearchFormFieldName.optionalNutritionType,
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText:
                          l10n.inventoryReceiptReviewManualNutritionTypeLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final type in availableTypes)
                        DropdownMenuItem<
                          models.InventoryReceiptOptionalNutritionType
                        >(
                          value: type,
                          child: Text(
                            _optionalNutritionTypeLabel(l10n, type),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: onTypeChanged,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton.outlined(
              key: const Key(
                'receipt_review_manual_optional_nutrition_cancel_button',
              ),
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              tooltip: l10n.inventoryReceiptReviewCancelAction,
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              key: const Key(
                'receipt_review_manual_optional_nutrition_confirm_button',
              ),
              onPressed: canApply ? onApply : null,
              icon: const Icon(Icons.check),
              tooltip: l10n.inventoryReceiptReviewManualDataSaveAction,
            ),
          ],
        ),
      ],
    );
  }
}

String _optionalNutritionTypeLabel(
  AppLocalizations l10n,
  models.InventoryReceiptOptionalNutritionType type,
) {
  return switch (type) {
    models.InventoryReceiptOptionalNutritionType.polyunsaturatedFat =>
      l10n.caloriesPer100PolyunsaturatedFatLabel,
    models.InventoryReceiptOptionalNutritionType.fiber =>
      l10n.caloriesPer100FiberLabel,
  };
}
