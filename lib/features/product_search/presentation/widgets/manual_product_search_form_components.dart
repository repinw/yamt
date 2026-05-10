// Extracted internal widget bucket for manual product search form UI pieces.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'inventory_product_candidate_widgets.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

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

final manualProductNumericInputFormatters = <TextInputFormatter>[
  manualProductSingleDecimalInputFormatter,
];

abstract final class ManualProductSearchFormFieldName {
  static const name = 'manual_product_name';
  static const brand = 'manual_product_brand';
  static const weightAmount = 'manual_product_weight_amount';
  static const weightUnit = 'manual_product_weight_unit';
  static const kcal = 'manual_product_kcal';
  static const fat = 'manual_product_fat';
  static const saturatedFat = 'manual_product_saturated_fat';
  static const carbs = 'manual_product_carbs';
  static const sugar = 'manual_product_sugar';
  static const protein = 'manual_product_protein';
  static const salt = 'manual_product_salt';
  static const polyunsaturatedFat = 'manual_product_polyunsaturated_fat';
  static const fiber = 'manual_product_fiber';
  static const optionalNutritionValue = 'manual_product_optional_value';
  static const optionalNutritionUnit = 'manual_product_optional_unit';
  static const optionalNutritionType = 'manual_product_optional_type';
}

String _sanitizeDecimalInput(String rawText) {
  final buffer = StringBuffer();
  var hasSeparator = false;

  for (final codeUnit in rawText.codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    if (isDigit) {
      buffer.writeCharCode(codeUnit);
      continue;
    }

    final isSeparator = codeUnit == 44 || codeUnit == 46;
    if (!hasSeparator && isSeparator) {
      hasSeparator = true;
      buffer.writeCharCode(codeUnit);
    }
  }

  return buffer.toString();
}

/// Defines inventory receipt manual product preview data.
class InventoryReceiptManualProductPreviewData {
  /// The inventory receipt manual product preview data.
  const InventoryReceiptManualProductPreviewData({
    required this.imageUrl,
    required this.name,
    this.brand,
    this.weight,
  });

  /// The image url.
  final String? imageUrl;

  /// The name.
  final String name;

  /// The brand.
  final String? brand;

  /// The weight.
  final String? weight;
}

class ManualProductSearchShell extends StatelessWidget {
  const ManualProductSearchShell({
    required this.title,
    required this.searchBar,
    required this.body,
    required this.onClose,
    super.key,
  });

  final String title;
  final Widget searchBar;
  final Widget body;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl + insets,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ManualProductDialogHeader(title: title, onClose: onClose),
            const SizedBox(height: AppSpacing.lg),
            Theme(
              data: _buildSearchToolbarTheme(context),
              child: searchBar,
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(height: AppSpacing.lg),
            body,
          ],
        ),
      ),
    );
  }
}

class ManualProductSearchToolbar extends StatelessWidget {
  const ManualProductSearchToolbar({
    required this.searchController,
    required this.onAiSearchTap,
    required this.onScanBarcode,
    required this.clearButtonKey,
    required this.fieldKey,
    super.key,
    this.isSearching = false,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.onVoiceSearchPressed,
    this.voiceSearchService,
    this.voiceSearchController,
    this.startVoiceSearchOnMount = false,
  });

  final TextEditingController searchController;
  final VoidCallback onAiSearchTap;
  final VoidCallback onScanBarcode;
  final Key clearButtonKey;
  final Key fieldKey;
  final bool isSearching;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onVoiceSearchPressed;
  final VoiceSearchService? voiceSearchService;
  final TextVoiceSearchController? voiceSearchController;
  final bool startVoiceSearchOnMount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextVoiceSearchBar(
          controller: searchController,
          label: l10n.inventoryReceiptReviewManualSearchLabel,
          hintText: l10n.inventoryReceiptReviewManualSearchLabel,
          isSearching: isSearching,
          voiceButtonKey: const Key(
            'receipt_review_manual_voice_search_button',
          ),
          clearButtonKey: clearButtonKey,
          fieldKey: fieldKey,
          readOnly: readOnly,
          autofocus: autofocus,
          onTap: onTap,
          onChanged: onChanged,
          onVoiceSearchPressed: onVoiceSearchPressed,
          voiceSearchService: voiceSearchService,
          voiceSearchController: voiceSearchController,
          startVoiceSearchOnMount: startVoiceSearchOnMount,
        ),
        const SizedBox(height: AppSpacing.sm),
        ManualProductQuickActionsRow(
          onAiSearchTap: onAiSearchTap,
          onScanBarcode: onScanBarcode,
        ),
      ],
    );
  }
}

ThemeData _buildSearchToolbarTheme(BuildContext context) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.xl),
  );

  return theme.copyWith(
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      hintStyle: theme.textTheme.bodyLarge?.copyWith(
        color: colors.onSurfaceVariant,
      ),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.96),
      prefixIconColor: colors.primary,
      suffixIconColor: colors.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.82)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.96),
        foregroundColor: colors.onSurfaceVariant,
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.72),
        ),
        shape: shape,
      ),
    ),
  );
}

class ManualProductDialogHeader extends StatelessWidget {
  const ManualProductDialogHeader({
    required this.title,
    required this.onClose,
    super.key,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow.withValues(alpha: 0.96),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: CloseButton(
            color: colors.onSurfaceVariant,
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}

class ManualProductActionSelector extends StatelessWidget {
  const ManualProductActionSelector({
    required this.selectedAction,
    this.onChanged,
    super.key,
  });

  final InventoryReceiptManualProductAction selectedAction;
  final ValueChanged<InventoryReceiptManualProductAction>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('receipt_review_manual_inventory_action_button'),
            onPressed: onChanged == null
                ? null
                : () => onChanged!(
                    InventoryReceiptManualProductAction.addToInventory,
                  ),
            style: _buttonStyle(
              context: context,
              isSelected:
                  selectedAction ==
                  InventoryReceiptManualProductAction.addToInventory,
            ),
            child: Text(l10n.inventoryManualAddResultActionInventory),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton(
            key: const Key('receipt_review_manual_eat_action_button'),
            onPressed: onChanged == null
                ? null
                : () => onChanged!(InventoryReceiptManualProductAction.eatNow),
            style: _buttonStyle(
              context: context,
              isSelected:
                  selectedAction == InventoryReceiptManualProductAction.eatNow,
            ),
            child: Text(l10n.inventoryManualAddResultActionEat),
          ),
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle({
    required BuildContext context,
    required bool isSelected,
  }) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      backgroundColor: isSelected ? colors.secondaryContainer : null,
      foregroundColor: isSelected ? colors.onSecondaryContainer : null,
      side: BorderSide(
        color: isSelected ? colors.secondary : colors.outlineVariant,
      ),
    );
  }
}

class ManualProductQuickActionsRow extends StatelessWidget {
  const ManualProductQuickActionsRow({
    required this.onAiSearchTap,
    required this.onScanBarcode,
    super.key,
  });

  final VoidCallback onAiSearchTap;
  final VoidCallback onScanBarcode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('receipt_review_manual_ai_search_button'),
            onPressed: onAiSearchTap,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(l10n.inventoryManualAddAiSearchAction),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('receipt_review_manual_scan_button'),
            onPressed: onScanBarcode,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(l10n.inventoryManualAddScanBarcodeAction),
          ),
        ),
      ],
    );
  }
}

class OptionalNutritionAddRow extends StatelessWidget {
  const OptionalNutritionAddRow({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
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

class OptionalNutritionComposer extends StatelessWidget {
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

  final String valueText;
  final InventoryAmountUnit selectedUnit;
  final InventoryReceiptOptionalNutritionType? selectedType;
  final List<InventoryReceiptOptionalNutritionType> availableTypes;
  final ValueChanged<String?> onValueChanged;
  final ValueChanged<InventoryAmountUnit?> onUnitChanged;
  final ValueChanged<InventoryReceiptOptionalNutritionType?> onTypeChanged;
  final VoidCallback onApply;
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
              child: FormBuilderDropdown<InventoryReceiptOptionalNutritionType>(
                key: const Key(
                  'receipt_review_manual_optional_nutrition_type_field',
                ),
                name: ManualProductSearchFormFieldName.optionalNutritionType,
                initialValue: selectedType,
                decoration: InputDecoration(
                  labelText:
                      l10n.inventoryReceiptReviewManualNutritionTypeLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final type in availableTypes)
                    DropdownMenuItem<InventoryReceiptOptionalNutritionType>(
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

class ManualProductWeightFields extends StatelessWidget {
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

  final String amountValue;
  final InventoryAmountUnit selectedUnit;
  final ValueChanged<String?> onAmountChanged;
  final ValueChanged<InventoryAmountUnit?> onUnitChanged;
  final Key amountFieldKey;
  final Key unitFieldKey;
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

String _optionalNutritionTypeLabel(
  AppLocalizations l10n,
  InventoryReceiptOptionalNutritionType type,
) {
  return switch (type) {
    InventoryReceiptOptionalNutritionType.polyunsaturatedFat =>
      l10n.caloriesPer100PolyunsaturatedFatLabel,
    InventoryReceiptOptionalNutritionType.fiber =>
      l10n.caloriesPer100FiberLabel,
  };
}

class ManualProductTextField extends StatelessWidget {
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

  final String name;
  final String initialValue;
  final String label;
  final Key fieldKey;
  final TextInputType keyboardType;
  final ValueChanged<String?> onChanged;
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

class ManualProductSearchResults extends StatelessWidget {
  const ManualProductSearchResults({
    required this.results,
    required this.onSelect,
    super.key,
    this.onStoreSelect,
    this.onEatSelect,
  });

  final List<OffProductSearchResult> results;
  final ValueChanged<OffProductSearchResult> onSelect;
  final ValueChanged<OffProductSearchResult>? onStoreSelect;
  final ValueChanged<OffProductSearchResult>? onEatSelect;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var index = 0; index < results.length; index++) ...[
          Builder(
            builder: (context) {
              final result = results[index];
              return InventoryProductCandidateTile(
                key: Key('receipt_review_manual_search_result_${result.code}'),
                name: result.name,
                brand: result.brand,
                imageUrl: result.imageUrl,
                packageWeight: result.packageWeight,
                nutrition: result.nutrition,
                onTap: () => onSelect(result),
                trailing: onEatSelect != null
                    ? _ManualProductSearchActions(
                        result: result,
                        onStore: onStoreSelect,
                        onEat: onEatSelect!,
                      )
                    : null,
              );
            },
          ),
          if (index != results.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ManualProductSearchActions extends StatelessWidget {
  const _ManualProductSearchActions({
    required this.result,
    required this.onEat,
    this.onStore,
  });

  final OffProductSearchResult result;
  final ValueChanged<OffProductSearchResult> onEat;
  final ValueChanged<OffProductSearchResult>? onStore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InventoryProductCandidateActions(
      inventoryLabel: l10n.inventoryManualAddResultActionInventory,
      eatLabel: l10n.inventoryManualAddResultActionEat,
      inventoryButtonKey: Key(
        'receipt_review_manual_search_result_store_button_${result.code}',
      ),
      eatButtonKey: Key(
        'receipt_review_manual_search_result_eat_button_${result.code}',
      ),
      showInventoryAction: onStore != null,
      onInventory: () => onStore?.call(result),
      onEat: () => onEat(result),
    );
  }
}

class ManualProductRecentItems extends StatelessWidget {
  const ManualProductRecentItems({
    required this.items,
    required this.onSelect,
    super.key,
    this.onStoreSelect,
    this.onEatSelect,
  });

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onSelect;
  final ValueChanged<InventoryItem>? onStoreSelect;
  final ValueChanged<InventoryItem>? onEatSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventoryReceiptReviewRecentProductsTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Builder(
                builder: (context) {
                  final item = items[index];
                  final inventoryButtonKey = Key(
                    'receipt_review_manual_recent_item_store_button_'
                    '${item.id}',
                  );
                  final eatButtonKey = Key(
                    'receipt_review_manual_recent_item_eat_button_'
                    '${item.id}',
                  );
                  return InventoryProductCandidateTile(
                    key: Key('receipt_review_manual_recent_item_${item.id}'),
                    name: item.name,
                    brand: item.brand,
                    imageUrl: item.imageUrl,
                    packageWeight: item.weight,
                    nutrition: item.nutrition,
                    onTap: () => onSelect(item),
                    trailing: onEatSelect != null
                        ? InventoryProductCandidateActions(
                            inventoryLabel:
                                l10n.inventoryManualAddResultActionInventory,
                            eatLabel: l10n.inventoryManualAddResultActionEat,
                            inventoryButtonKey: inventoryButtonKey,
                            eatButtonKey: eatButtonKey,
                            showInventoryAction: onStoreSelect != null,
                            onInventory: () => onStoreSelect?.call(item),
                            onEat: () => onEatSelect!(item),
                          )
                        : null,
                  );
                },
              ),
              if (index != items.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ],
    );
  }
}

class ManualProductPreview extends StatelessWidget {
  const ManualProductPreview({
    required this.preview,
    super.key,
  });

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
            child: _PreviewImage(imageUrl: preview.imageUrl),
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

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedUrl = normalizeProductImageUrl(imageUrl);
    if (resolvedUrl == null) {
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
    }

    return AppCachedNetworkImage(
      imageUrl: resolvedUrl,
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
    );
  }
}
