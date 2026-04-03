import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
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
    required this.searchController,
    required this.isSearching,
    required this.showDetails,
    required this.searchResults,
    required this.weightAmountController,
    required this.selectedWeightUnit,
    required this.kcalController,
    required this.fatController,
    required this.carbsController,
    required this.proteinController,
    required this.preview,
    required this.errorText,
    required this.onSearchResultSelected,
    required this.onScanBarcode,
    required this.onWeightUnitChanged,
    required this.onScanNutritionLabel,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController searchController;
  final bool isSearching;
  final bool showDetails;
  final List<OffProductSearchResult> searchResults;
  final TextEditingController weightAmountController;
  final InventoryAmountUnit selectedWeightUnit;
  final TextEditingController kcalController;
  final TextEditingController fatController;
  final TextEditingController carbsController;
  final TextEditingController proteinController;
  final InventoryReceiptManualProductPreviewData? preview;
  final String? errorText;
  final ValueChanged<OffProductSearchResult> onSearchResultSelected;
  final VoidCallback onScanBarcode;
  final ValueChanged<InventoryAmountUnit> onWeightUnitChanged;
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
            _ManualProductSearchBar(
              controller: searchController,
              isSearching: isSearching,
              onScanBarcode: onScanBarcode,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ManualProductSearchResults(
              results: searchResults,
              onSelect: onSearchResultSelected,
            ),
            if (showDetails && preview != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ManualProductPreview(preview: preview!),
            ],
            if (showDetails) ...[
              const SizedBox(height: AppSpacing.lg),
              _ManualProductWeightFields(
                amountController: weightAmountController,
                selectedUnit: selectedWeightUnit,
                onUnitChanged: onWeightUnitChanged,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('receipt_review_manual_nutrition_ocr_button'),
                  onPressed: onScanNutritionLabel,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(
                    AppLocalizations.of(
                      context,
                    )!.caloriesBarcodeNotFoundOcrAction,
                  ),
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
                        AppLocalizations.of(
                          context,
                        )!.inventoryReceiptReviewManualDataSaveAction,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ManualProductWeightFields extends StatelessWidget {
  const _ManualProductWeightFields({
    required this.amountController,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  final TextEditingController amountController;
  final InventoryAmountUnit selectedUnit;
  final ValueChanged<InventoryAmountUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _ManualProductTextField(
            controller: amountController,
            label: l10n.inventoryReceiptReviewFieldWeight,
            fieldKey: const Key('receipt_review_manual_weight_field'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<InventoryAmountUnit>(
            key: const Key('receipt_review_manual_weight_unit_field'),
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
            onChanged: (value) {
              if (value != null) {
                onUnitChanged(value);
              }
            },
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

class _ManualProductSearchBar extends StatelessWidget {
  const _ManualProductSearchBar({
    required this.controller,
    required this.isSearching,
    required this.onScanBarcode,
  });

  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onScanBarcode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ManualProductTextField(
            controller: controller,
            label: l10n.inventoryReceiptReviewProductSelectionLabel,
            fieldKey: const Key('receipt_review_manual_search_field'),
            keyboardType: TextInputType.text,
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: 56,
          width: 56,
          child: IconButton.outlined(
            key: const Key('receipt_review_manual_scan_button'),
            onPressed: onScanBarcode,
            tooltip: l10n.inventoryBarcodeMissingPromptScanNow,
            icon: const Icon(Icons.qr_code_scanner_outlined),
          ),
        ),
      ],
    );
  }
}

class _ManualProductTextField extends StatelessWidget {
  const _ManualProductTextField({
    required this.controller,
    required this.label,
    required this.fieldKey,
    required this.keyboardType,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _ManualProductSearchResults extends StatelessWidget {
  const _ManualProductSearchResults({
    required this.results,
    required this.onSelect,
  });

  final List<OffProductSearchResult> results;
  final ValueChanged<OffProductSearchResult> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: colors.outlineVariant),
        itemBuilder: (context, index) {
          final result = results[index];
          return InkWell(
            key: Key('receipt_review_manual_search_result_${result.code}'),
            onTap: () => onSelect(result),
            child: Padding(
              padding: AppInsets.card,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ManualProductSearchImage(imageUrl: result.imageUrl),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _ManualProductSearchDetails(result: result)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManualProductSearchDetails extends StatelessWidget {
  const _ManualProductSearchDetails({required this.result});

  final OffProductSearchResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final brand = normalizeManualProductText(result.brand ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall,
        ),
        if (brand != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        if (result.nutrition?.hasAnyNutritionValue == true) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            children: [
              if (result.nutrition?.per100Kcal != null)
                _ManualProductNutritionValue(
                  value: result.nutrition!.per100Kcal!.round().toString(),
                  label: l10n.caloriesUnitKcal,
                ),
              if (result.nutrition?.per100Carbs != null)
                _ManualProductNutritionValue(
                  value: _formatNutritionValue(result.nutrition!.per100Carbs!),
                  label: l10n.inventoryNutritionCarbsShortLabel,
                ),
              if (result.nutrition?.per100Protein != null)
                _ManualProductNutritionValue(
                  value: _formatNutritionValue(
                    result.nutrition!.per100Protein!,
                  ),
                  label: l10n.caloriesProteinLabel,
                ),
              if (result.nutrition?.per100Fat != null)
                _ManualProductNutritionValue(
                  value: _formatNutritionValue(result.nutrition!.per100Fat!),
                  label: l10n.caloriesFatLabel,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ManualProductNutritionValue extends StatelessWidget {
  const _ManualProductNutritionValue({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$value ',
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: label),
        ],
      ),
      style: textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ManualProductSearchImage extends StatelessWidget {
  const _ManualProductSearchImage({required this.imageUrl});

  static const _imageSize = 48.0;

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedUrl = normalizeManualProductText(imageUrl ?? '');
    if (resolvedUrl == null) {
      return SizedBox.square(
        dimension: _imageSize,
        child: Icon(
          Icons.inventory_2_outlined,
          size: _imageSize,
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.network(
        resolvedUrl,
        width: _imageSize,
        height: _imageSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox.square(
            dimension: _imageSize,
            child: Icon(
              Icons.inventory_2_outlined,
              size: _imageSize,
              color: colors.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
}

String _formatNutritionValue(double value) {
  final hasFraction = value % 1 != 0;
  return hasFraction ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
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
      key: const Key('receipt_review_manual_preview'),
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
                  key: const Key('receipt_review_manual_preview_name'),
                  preview.name,
                  style: textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (brand != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    key: const Key('receipt_review_manual_preview_brand'),
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
                    key: const Key('receipt_review_manual_preview_weight'),
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
