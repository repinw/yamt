import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_inline_amount_field.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Head of the product editor, drawn like the head of the eat page: the
/// image tile, the brand and the name as inputs, then the package size.
class ManualProductEditorHeader extends StatelessWidget {
  /// Creates the head.
  const new({
    required this.imageUrl,
    required this.texts,
    required this.focusNodes,
    required this.weightUnit,
    required this.onFieldChanged,
    required this.onFieldSubmitted,
    required this.onWeightUnitChanged,
    super.key,
  });

  /// Key of the button that switches the package unit.
  static const weightUnitKey = Key('receipt_review_manual_weight_unit_field');

  /// Product image address.
  final String? imageUrl;

  /// Text of each input.
  final Map<ManualProductFormField, TextEditingController> texts;

  /// Focus of each input.
  final Map<ManualProductFormField, FocusNode> focusNodes;

  /// Unit of the package size, or null until the user picks one.
  final InventoryAmountUnit? weightUnit;

  /// Called when an input changes.
  final void Function(ManualProductFormField field, String text) onFieldChanged;

  /// Called when an input is confirmed on the keyboard.
  final ValueChanged<ManualProductFormField> onFieldSubmitted;

  /// Called with the next package unit.
  final ValueChanged<InventoryAmountUnit> onWeightUnitChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final unit = weightUnit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          spacing: AppSpacing.xl,
          children: [
            EatImageTile(imageUrl: imageUrl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.xs,
                children: [
                  _HeadInput(
                    field: ManualProductFormField.brand,
                    wiring: _wiring(ManualProductFormField.brand),
                    hint: l10n.inventoryReceiptReviewFieldBrand,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.muted,
                      letterSpacing: AppFoodLabel.brandTracking,
                    ),
                  ),
                  _HeadInput(
                    field: ManualProductFormField.name,
                    wiring: _wiring(ManualProductFormField.name),
                    hint: l10n.inventoryReceiptReviewFieldName,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        EatInlineAmountField(
          fieldKey: ManualProductFormField.weightAmount.key,
          label: l10n.inventoryManualAddPackageSizeLabel,
          unitLabel: unit == null
              ? l10n.inventoryReceiptReviewFieldWeightUnit
              : _unitLabel(l10n, unit),
          controller: texts[ManualProductFormField.weightAmount]!,
          focusNode: focusNodes[ManualProductFormField.weightAmount]!,
          onChanged: (text) =>
              onFieldChanged(ManualProductFormField.weightAmount, text),
          unitKey: weightUnitKey,
          onUnitPressed: () => onWeightUnitChanged(_nextUnit(unit)),
          isAmountMissing: texts[ManualProductFormField.weightAmount]!.text
              .trim()
              .isEmpty,
          isUnitMissing: unit == null,
        ),
      ],
    );
  }

  _HeadInputWiring _wiring(ManualProductFormField field) => (
    controller: texts[field]!,
    focusNode: focusNodes[field]!,
    onChanged: (text) => onFieldChanged(field, text),
    onSubmitted: () => onFieldSubmitted(field),
  );

  static InventoryAmountUnit _nextUnit(InventoryAmountUnit? unit) {
    const units = InventoryAmountUnit.values;
    return unit == null ? units.first : units[(unit.index + 1) % units.length];
  }

  static String _unitLabel(AppLocalizations l10n, InventoryAmountUnit unit) {
    return switch (unit) {
      InventoryAmountUnit.gram => l10n.caloriesUnitGram,
      InventoryAmountUnit.milliliter => l10n.inventoryUnitMilliliter,
      InventoryAmountUnit.piece => l10n.inventoryReceiptReviewWeightUnitPiece,
    };
  }
}

typedef _HeadInputWiring = ({
  TextEditingController controller,
  FocusNode focusNode,
  ValueChanged<String> onChanged,
  VoidCallback onSubmitted,
});

/// A borderless input of the head with a quiet underline. A required input
/// that is still empty gets an accent underline.
class _HeadInput extends StatelessWidget {
  const new({
    required this.field,
    required this.wiring,
    required this.hint,
    required this.style,
  });

  final ManualProductFormField field;
  final _HeadInputWiring wiring;
  final String hint;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final controller = wiring.controller;
    final isMissing = field.isRequired && controller.text.trim().isEmpty;

    return TextField(
      key: field.key,
      controller: controller,
      focusNode: wiring.focusNode,
      textInputAction: field.isRequired ? TextInputAction.next : null,
      cursorColor: colors.ink,
      style: style,
      onChanged: wiring.onChanged,
      onSubmitted: (_) => wiring.onSubmitted(),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: style?.copyWith(color: colors.muted),
        contentPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
        enabledBorder: UnderlineInputBorder(
          borderSide: isMissing
              ? BorderSide(color: colors.accent, width: AppFoodLabel.outline)
              : BorderSide(color: colors.rule),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: colors.ink,
            width: AppFoodLabel.outline,
          ),
        ),
      ),
    );
  }
}
