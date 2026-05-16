import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

final int _zeroCodeUnit = '0'.codeUnitAt(0);
final int _nineCodeUnit = '9'.codeUnitAt(0);
final int _commaCodeUnit = ','.codeUnitAt(0);
final int _periodCodeUnit = '.'.codeUnitAt(0);

/// Decimal input formatter used by manual product nutrition fields.
final TextInputFormatter manualProductSingleDecimalInputFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
      final sanitizedText = _sanitizeDecimalInput(newValue.text);
      if (sanitizedText == newValue.text) {
        return newValue;
      }
      return TextEditingValue(
        text: sanitizedText,
        selection: TextSelection.collapsed(offset: sanitizedText.length),
      );
    });

/// Numeric formatters used by manual product nutrition fields.
final manualProductNumericInputFormatters = <TextInputFormatter>[
  manualProductSingleDecimalInputFormatter,
];

/// Form field names for manual product search.
abstract final class ManualProductSearchFormFieldName {
  /// Product name.
  static const name = 'manual_product_name';

  /// Product brand.
  static const brand = 'manual_product_brand';

  /// Weight amount.
  static const weightAmount = 'manual_product_weight_amount';

  /// Weight unit.
  static const weightUnit = 'manual_product_weight_unit';

  /// Kcal field.
  static const kcal = 'manual_product_kcal';

  /// Fat field.
  static const fat = 'manual_product_fat';

  /// Saturated fat field.
  static const saturatedFat = 'manual_product_saturated_fat';

  /// Carbs field.
  static const carbs = 'manual_product_carbs';

  /// Sugar field.
  static const sugar = 'manual_product_sugar';

  /// Protein field.
  static const protein = 'manual_product_protein';

  /// Salt field.
  static const salt = 'manual_product_salt';

  /// Polyunsaturated fat field.
  static const polyunsaturatedFat = 'manual_product_polyunsaturated_fat';

  /// Fiber field.
  static const fiber = 'manual_product_fiber';

  /// Optional nutrition value field.
  static const optionalNutritionValue = 'manual_product_optional_value';

  /// Optional nutrition unit field.
  static const optionalNutritionUnit = 'manual_product_optional_unit';

  /// Optional nutrition type field.
  static const optionalNutritionType = 'manual_product_optional_type';
}

/// Weight amount and unit fields.
class ManualProductWeightFields extends StatelessWidget {
  /// Creates weight fields.
  const ManualProductWeightFields({
    required this.amountValue,
    required this.selectedUnit,
    required this.onAmountChanged,
    required this.onUnitChanged,
    required this.amountFieldKey,
    required this.unitFieldKey,
    required this.amountLabel,
    super.key,
  });

  /// Current amount text.
  final String amountValue;

  /// Selected weight unit.
  final InventoryAmountUnit selectedUnit;

  /// Called when amount changes.
  final ValueChanged<String?> onAmountChanged;

  /// Called when unit changes.
  final ValueChanged<InventoryAmountUnit?> onUnitChanged;

  /// Amount field key.
  final Key amountFieldKey;

  /// Unit field key.
  final Key unitFieldKey;

  /// Amount label.
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: ManualProductTextField(
            name: ManualProductSearchFormFieldName.weightAmount,
            initialValue: amountValue,
            label: amountLabel,
            fieldKey: amountFieldKey,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: manualProductNumericInputFormatters,
            onChanged: onAmountChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: FormBuilderDropdown<InventoryAmountUnit>(
            key: unitFieldKey,
            name: ManualProductSearchFormFieldName.weightUnit,
            initialValue: selectedUnit,
            decoration: InputDecoration(
              labelText: l10n.inventoryReceiptReviewFieldWeightUnit,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final unit in InventoryAmountUnit.values)
                DropdownMenuItem<InventoryAmountUnit>(
                  value: unit,
                  child: Text(_weightUnitLabel(l10n, unit)),
                ),
            ],
            onChanged: onUnitChanged,
          ),
        ),
      ],
    );
  }

  String _weightUnitLabel(AppLocalizations l10n, InventoryAmountUnit unit) {
    return switch (unit) {
      InventoryAmountUnit.gram => l10n.inventoryReceiptReviewWeightUnitGram,
      InventoryAmountUnit.milliliter => l10n.inventoryUnitMilliliter,
      InventoryAmountUnit.piece => l10n.inventoryReceiptReviewWeightUnitPiece,
    };
  }
}

/// Manual product text field.
class ManualProductTextField extends StatelessWidget {
  /// Creates a manual product text field.
  const ManualProductTextField({
    required this.name,
    required this.initialValue,
    required this.label,
    required this.fieldKey,
    required this.keyboardType,
    required this.onChanged,
    super.key,
    this.inputFormatters,
  });

  /// Form field name.
  final String name;

  /// Initial text value.
  final String initialValue;

  /// Field label.
  final String label;

  /// Widget key.
  final Key fieldKey;

  /// Keyboard type.
  final TextInputType keyboardType;

  /// Called when text changes.
  final ValueChanged<String?> onChanged;

  /// Optional input formatters.
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      key: fieldKey,
      name: name,
      initialValue: initialValue,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

String _sanitizeDecimalInput(String rawText) {
  final buffer = StringBuffer();
  var hasSeparator = false;

  for (final codeUnit in rawText.codeUnits) {
    final isDigit = codeUnit >= _zeroCodeUnit && codeUnit <= _nineCodeUnit;
    if (isDigit) {
      buffer.writeCharCode(codeUnit);
      continue;
    }

    final isSeparator =
        codeUnit == _commaCodeUnit || codeUnit == _periodCodeUnit;
    if (!hasSeparator && isSeparator) {
      hasSeparator = true;
      buffer.writeCharCode(codeUnit);
    }
  }

  return buffer.toString();
}
