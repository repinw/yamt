import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryReceiptManualProductSheet extends StatefulWidget {
  const InventoryReceiptManualProductSheet({super.key, required this.item});

  final InventoryItem item;

  @override
  State<InventoryReceiptManualProductSheet> createState() =>
      _InventoryReceiptManualProductSheetState();
}

class _InventoryReceiptManualProductSheetState
    extends State<InventoryReceiptManualProductSheet> {
  late final TextEditingController _barcodeController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final nutrition = widget.item.nutrition;
    _barcodeController = TextEditingController(
      text: widget.item.normalizedBarcode ?? '',
    );
    _kcalController = TextEditingController(
      text: _formatDouble(nutrition?.per100Kcal),
    );
    _proteinController = TextEditingController(
      text: _formatDouble(nutrition?.per100Protein),
    );
    _carbsController = TextEditingController(
      text: _formatDouble(nutrition?.per100Carbs),
    );
    _fatController = TextEditingController(
      text: _formatDouble(nutrition?.per100Fat),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + insets,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventoryReceiptReviewManualDataTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.inventoryReceiptReviewManualDataHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _barcodeController,
              label: l10n.inventoryReceiptReviewManualDataBarcodeLabel,
              key: const Key('receipt_review_manual_barcode_field'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _kcalController,
              label: l10n.caloriesPer100KcalLabel,
              key: const Key('receipt_review_manual_kcal_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _proteinController,
              label: l10n.caloriesPer100ProteinLabel,
              key: const Key('receipt_review_manual_protein_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _carbsController,
              label: l10n.caloriesPer100CarbsLabel,
              key: const Key('receipt_review_manual_carbs_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _fatController,
              label: l10n.caloriesPer100FatLabel,
              key: const Key('receipt_review_manual_fat_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            if (_errorText case final String message) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.inventoryReceiptReviewCancelAction),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('receipt_review_manual_save_button'),
                    onPressed: _save,
                    child: Text(
                      l10n.inventoryReceiptReviewManualDataSaveAction,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Key key,
    required TextInputType keyboardType,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _save() {
    final barcode = _normalizeText(_barcodeController.text);
    final kcal = _parseDouble(_kcalController.text);
    final protein = _parseDouble(_proteinController.text);
    final carbs = _parseDouble(_carbsController.text);
    final fat = _parseDouble(_fatController.text);

    final hasNutrition =
        kcal != null || protein != null || carbs != null || fat != null;
    if (barcode == null && !hasNutrition) {
      setState(() {
        _errorText = AppLocalizations.of(
          context,
        )!.inventoryReceiptReviewManualDataRequired;
      });
      return;
    }

    final updatedItem = widget.item.copyWith(
      barcode: barcode,
      nutrition: hasNutrition
          ? GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: kcal,
              per100Protein: protein,
              per100Carbs: carbs,
              per100Fat: fat,
            )
          : widget.item.nutrition,
    );
    Navigator.of(context).pop(updatedItem);
  }
}

String? _normalizeText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

double? _parseDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return double.tryParse(trimmed.replaceAll(',', '.'));
}

String _formatDouble(double? value) {
  if (value == null) {
    return '';
  }
  if (value.truncateToDouble() == value) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
