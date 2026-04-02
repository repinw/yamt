import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

import 'inventory_receipt_manual_product_form_utils.dart';

class InventoryReceiptManualProductPreviewData {
  const InventoryReceiptManualProductPreviewData({
    required this.imageUrl,
    required this.name,
    this.brand,
    this.weight,
  });

  final String imageUrl;
  final String name;
  final String? brand;
  final String? weight;
}

class InventoryReceiptManualProductForm extends StatelessWidget {
  const InventoryReceiptManualProductForm({
    super.key,
    required this.barcodeController,
    required this.kcalController,
    required this.fatController,
    required this.carbsController,
    required this.proteinController,
    required this.preview,
    required this.errorText,
    required this.onScanBarcode,
    required this.onScanNutritionLabel,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController barcodeController;
  final TextEditingController kcalController;
  final TextEditingController fatController;
  final TextEditingController carbsController;
  final TextEditingController proteinController;
  final InventoryReceiptManualProductPreviewData? preview;
  final String? errorText;
  final VoidCallback onScanBarcode;
  final VoidCallback? onScanNutritionLabel;
  final VoidCallback onCancel;
  final VoidCallback onSave;

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
            if (preview != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ManualProductPreview(preview: preview!),
            ],
            const SizedBox(height: AppSpacing.lg),
            _ManualProductTextField(
              controller: barcodeController,
              label: l10n.inventoryReceiptReviewManualDataBarcodeLabel,
              fieldKey: const Key('receipt_review_manual_barcode_field'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('receipt_review_manual_scan_button'),
                onPressed: onScanBarcode,
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: Text(l10n.inventoryBarcodeMissingPromptScanNow),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('receipt_review_manual_nutrition_ocr_button'),
                onPressed: onScanNutritionLabel,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(l10n.caloriesBarcodeNotFoundOcrAction),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ManualProductTextField(
              controller: kcalController,
              label: l10n.caloriesPer100KcalLabel,
              fieldKey: const Key('receipt_review_manual_kcal_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ManualProductTextField(
              controller: fatController,
              label: l10n.caloriesPer100FatLabel,
              fieldKey: const Key('receipt_review_manual_fat_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ManualProductTextField(
              controller: carbsController,
              label: l10n.caloriesPer100CarbsLabel,
              fieldKey: const Key('receipt_review_manual_carbs_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ManualProductTextField(
              controller: proteinController,
              label: l10n.caloriesPer100ProteinLabel,
              fieldKey: const Key('receipt_review_manual_protein_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            if (errorText case final String message) ...[
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
                    onPressed: onCancel,
                    child: Text(l10n.inventoryReceiptReviewCancelAction),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('receipt_review_manual_save_button'),
                    onPressed: onSave,
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
}

class _ManualProductTextField extends StatelessWidget {
  const _ManualProductTextField({
    required this.controller,
    required this.label,
    required this.fieldKey,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ManualProductPreview extends StatelessWidget {
  const _ManualProductPreview({required this.preview});

  final InventoryReceiptManualProductPreviewData preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brand = normalizeManualProductText(preview.brand ?? '');
    final weight = normalizeManualProductText(preview.weight ?? '');

    return Container(
      width: double.infinity,
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.network(
              preview.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: SizedBox.square(
                    dimension: 72,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.name,
                  style: textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (brand != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    brand,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (weight != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    weight,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
