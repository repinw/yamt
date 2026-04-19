import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/widgets/inventory_product_candidate_widgets.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form_utils.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

final TextInputFormatter _singleDecimalInputFormatter =
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

final _numericInputFormatters = <TextInputFormatter>[
  _singleDecimalInputFormatter,
];

abstract final class _ManualProductFormFieldName {
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

/// Defines inventory receipt manual product launcher content.
class InventoryReceiptManualProductLauncherContent extends StatelessWidget {
  /// The inventory receipt manual product launcher content.
  const InventoryReceiptManualProductLauncherContent({
    required this.title,
    required this.searchController,
    required this.recentItems,
    required this.onClose,
    required this.onSearchTap,
    required this.onVoiceSearchTap,
    required this.onRecentItemSelected,
    required this.onScanBarcode,
    super.key,
    this.showRecentItemActions = false,
    this.onRecentItemStoreSelected,
    this.onRecentItemEatSelected,
  });

  /// Dialog title.
  final String title;

  /// The search controller.
  final TextEditingController searchController;

  /// The recent items.
  final List<InventoryItem> recentItems;

  /// Close action.
  final VoidCallback onClose;

  /// The on search tap.
  final VoidCallback onSearchTap;

  /// The on voice search tap.
  final VoidCallback onVoiceSearchTap;

  /// The on recent item selected.
  final ValueChanged<InventoryItem> onRecentItemSelected;

  /// The on scan barcode.
  final VoidCallback onScanBarcode;

  /// Whether recent items show action buttons.
  final bool showRecentItemActions;

  /// The on recent item store selected.
  final ValueChanged<InventoryItem>? onRecentItemStoreSelected;

  /// The on recent item eat selected.
  final ValueChanged<InventoryItem>? onRecentItemEatSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _ManualProductSearchShell(
      title: title,
      onClose: onClose,
      searchBar: TextVoiceSearchBar(
        controller: searchController,
        label: l10n.inventoryReceiptReviewManualSearchLabel,
        hintText: l10n.inventoryReceiptReviewManualSearchLabel,
        voiceButtonKey: const Key('receipt_review_manual_voice_search_button'),
        clearButtonKey: const Key(
          'receipt_review_manual_launcher_search_clear_button',
        ),
        fieldKey: const Key('receipt_review_manual_launcher_search_field'),
        readOnly: true,
        onTap: onSearchTap,
        onVoiceSearchPressed: onVoiceSearchTap,
        trailingActions: <Widget>[
          SizedBox(
            height: 56,
            width: 56,
            child: IconButton.outlined(
              key: const Key('receipt_review_manual_scan_button'),
              onPressed: onScanBarcode,
              tooltip: l10n.inventoryBarcodeMissingPromptScanNow,
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ),
        ],
      ),
      body: _ManualProductRecentItems(
        items: recentItems,
        onSelect: onRecentItemSelected,
        onStoreSelect: showRecentItemActions ? onRecentItemStoreSelected : null,
        onEatSelect: showRecentItemActions ? onRecentItemEatSelected : null,
      ),
    );
  }
}

/// Defines inventory receipt manual product form.
class InventoryReceiptManualProductForm extends StatelessWidget {
  /// The inventory receipt manual product form.
  const InventoryReceiptManualProductForm({
    required this.title,
    required this.searchController,
    required this.nameController,
    required this.brandController,
    required this.isSearching,
    required this.canSave,
    required this.isRunningNutritionOcr,
    required this.showDetails,
    required this.searchResults,
    required this.recentItems,
    required this.weightAmountController,
    required this.selectedWeightUnit,
    required this.kcalController,
    required this.saturatedFatController,
    required this.polyunsaturatedFatController,
    required this.showPolyunsaturatedFatField,
    required this.fatController,
    required this.carbsController,
    required this.sugarController,
    required this.fiberController,
    required this.showFiberField,
    required this.proteinController,
    required this.saltController,
    required this.canAddOptionalNutrition,
    required this.isAddingOptionalNutrition,
    required this.optionalNutritionValueController,
    required this.optionalNutritionUnit,
    required this.optionalNutritionType,
    required this.availableOptionalNutritionTypes,
    required this.preview,
    required this.errorText,
    required this.showActionSelector,
    required this.selectedAction,
    required this.onSearchResultSelected,
    required this.onRecentItemSelected,
    required this.onScanBarcode,
    required this.onWeightUnitChanged,
    required this.onScanNutritionLabel,
    required this.onStartAddingOptionalNutrition,
    required this.onOptionalNutritionUnitChanged,
    required this.onOptionalNutritionTypeChanged,
    required this.onApplyOptionalNutrition,
    required this.onCancelOptionalNutrition,
    required this.onCancel,
    required this.onSave,
    super.key,
    this.autofocusSearch = false,
    this.onSearchChanged,
    this.voiceSearchService,
    this.voiceSearchController,
    this.startVoiceSearchOnMount = false,
    this.onSearchResultStoreSelected,
    this.onSearchResultEatSelected,
    this.onActionChanged,
  });

  /// Dialog title.
  final String title;

  /// The search controller.
  final TextEditingController searchController;

  /// The name controller.
  final TextEditingController nameController;

  /// The brand controller.
  final TextEditingController brandController;

  /// Whether searching.
  final bool isSearching;

  /// Whether save.
  final bool canSave;

  /// Whether running nutrition ocr.
  final bool isRunningNutritionOcr;

  /// The autofocus search.
  final bool autofocusSearch;

  /// The show details.
  final bool showDetails;

  /// The search results.
  final List<OffProductSearchResult> searchResults;

  /// The recent items.
  final List<InventoryItem> recentItems;

  /// The weight amount controller.
  final TextEditingController weightAmountController;

  /// The selected weight unit.
  final InventoryAmountUnit selectedWeightUnit;

  /// The kcal controller.
  final TextEditingController kcalController;

  /// The saturated fat controller.
  final TextEditingController saturatedFatController;

  /// The polyunsaturated fat controller.
  final TextEditingController polyunsaturatedFatController;

  /// The show polyunsaturated fat field.
  final bool showPolyunsaturatedFatField;

  /// The fat controller.
  final TextEditingController fatController;

  /// The carbs controller.
  final TextEditingController carbsController;

  /// The sugar controller.
  final TextEditingController sugarController;

  /// The fiber controller.
  final TextEditingController fiberController;

  /// The show fiber field.
  final bool showFiberField;

  /// The protein controller.
  final TextEditingController proteinController;

  /// The salt controller.
  final TextEditingController saltController;

  /// Whether add optional nutrition.
  final bool canAddOptionalNutrition;

  /// Whether adding optional nutrition.
  final bool isAddingOptionalNutrition;

  /// The optional nutrition value controller.
  final TextEditingController optionalNutritionValueController;

  /// The optional nutrition unit.
  final InventoryAmountUnit optionalNutritionUnit;

  /// The optional nutrition type.
  final InventoryReceiptOptionalNutritionType? optionalNutritionType;

  /// Documented member.
  final List<InventoryReceiptOptionalNutritionType>
  availableOptionalNutritionTypes;

  /// The preview.
  final InventoryReceiptManualProductPreviewData? preview;

  /// The error text.
  final String? errorText;

  /// Whether action selector visible.
  final bool showActionSelector;

  /// The on search result selected.
  final ValueChanged<OffProductSearchResult> onSearchResultSelected;

  /// The on search result store selected.
  final ValueChanged<OffProductSearchResult>? onSearchResultStoreSelected;

  /// The on search result eat selected.
  final ValueChanged<OffProductSearchResult>? onSearchResultEatSelected;

  /// The on recent item selected.
  final ValueChanged<InventoryItem> onRecentItemSelected;

  /// The on scan barcode.
  final VoidCallback onScanBarcode;

  /// The on search changed.
  final ValueChanged<String>? onSearchChanged;

  /// The voice search service.
  final VoiceSearchService? voiceSearchService;

  /// The voice search controller.
  final TextVoiceSearchController? voiceSearchController;

  /// The start voice search on mount.
  final bool startVoiceSearchOnMount;

  /// The on weight unit changed.
  final ValueChanged<InventoryAmountUnit> onWeightUnitChanged;

  /// The on scan nutrition label.
  final VoidCallback? onScanNutritionLabel;

  /// The on start adding optional nutrition.
  final VoidCallback onStartAddingOptionalNutrition;

  /// The on optional nutrition unit changed.
  final ValueChanged<InventoryAmountUnit> onOptionalNutritionUnitChanged;

  /// Documented member.
  final ValueChanged<InventoryReceiptOptionalNutritionType>
  onOptionalNutritionTypeChanged;

  /// The on apply optional nutrition.
  final VoidCallback onApplyOptionalNutrition;

  /// The on cancel optional nutrition.
  final VoidCallback onCancelOptionalNutrition;

  /// The selected action.
  final InventoryReceiptManualProductAction selectedAction;

  /// The on action changed.
  final ValueChanged<InventoryReceiptManualProductAction>? onActionChanged;

  /// The on cancel.
  final VoidCallback onCancel;

  /// The on save.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return _ManualProductSearchShell(
      title: title,
      onClose: onCancel,
      searchBar: TextVoiceSearchBar(
        controller: searchController,
        label: l10n.inventoryReceiptReviewManualSearchLabel,
        hintText: l10n.inventoryReceiptReviewManualSearchLabel,
        isSearching: isSearching,
        voiceButtonKey: const Key('receipt_review_manual_voice_search_button'),
        clearButtonKey: const Key('receipt_review_manual_search_clear_button'),
        fieldKey: const Key('receipt_review_manual_search_field'),
        autofocus: autofocusSearch,
        onChanged: onSearchChanged,
        voiceSearchService: voiceSearchService,
        voiceSearchController: voiceSearchController,
        startVoiceSearchOnMount: startVoiceSearchOnMount,
        trailingActions: <Widget>[
          SizedBox(
            height: 56,
            width: 56,
            child: IconButton.outlined(
              key: const Key('receipt_review_manual_scan_button'),
              onPressed: onScanBarcode,
              tooltip: l10n.inventoryBarcodeMissingPromptScanNow,
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ),
        ],
      ),
      body: FormBuilder(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchResults.isNotEmpty)
              _ManualProductSearchResults(
                results: searchResults,
                onSelect: onSearchResultSelected,
                onStoreSelect: onSearchResultStoreSelected,
                onEatSelect: onSearchResultEatSelected,
              )
            else
              _ManualProductRecentItems(
                items: recentItems,
                onSelect: onRecentItemSelected,
              ),
            if (showDetails && preview != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ManualProductPreview(preview: preview!),
            ],
            if (showDetails) ...[
              const SizedBox(height: AppSpacing.lg),
              _ManualProductTextField(
                name: _ManualProductFormFieldName.name,
                controller: nameController,
                label: l10n.inventoryReceiptReviewFieldName,
                fieldKey: const Key('receipt_review_manual_name_field'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: AppSpacing.md),
              _ManualProductTextField(
                name: _ManualProductFormFieldName.brand,
                controller: brandController,
                label: l10n.inventoryReceiptReviewFieldBrand,
                fieldKey: const Key('receipt_review_manual_brand_field'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ManualProductWeightFields(
                amountController: weightAmountController,
                selectedUnit: selectedWeightUnit,
                onUnitChanged: onWeightUnitChanged,
                amountFieldKey: const Key('receipt_review_manual_weight_field'),
                unitFieldKey: const Key(
                  'receipt_review_manual_weight_unit_field',
                ),
                amountLabel: l10n.inventoryManualAddPackageSizeLabel,
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
                name: _ManualProductFormFieldName.kcal,
                controller: kcalController,
                label: l10n.caloriesPer100KcalLabel,
                fieldKey: const Key('receipt_review_manual_kcal_field'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _numericInputFormatters,
              ),
              const SizedBox(height: AppSpacing.md),
              _ManualProductTextField(
                name: _ManualProductFormFieldName.fat,
                controller: fatController,
                label: l10n.caloriesPer100FatLabel,
                fieldKey: const Key('receipt_review_manual_fat_field'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _numericInputFormatters,
              ),
              const SizedBox(height: AppSpacing.md),
              _ManualProductTextField(
                name: _ManualProductFormFieldName.saturatedFat,
                controller: saturatedFatController,
                label: l10n.caloriesPer100SaturatedFatLabel,
                fieldKey: const Key(
                  'receipt_review_manual_saturated_fat_field',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _numericInputFormatters,
              ),
              const SizedBox(height: AppSpacing.md),
              _ManualProductTextField(
                name: _ManualProductFormFieldName.carbs,
                controller: carbsController,
                label: l10n.caloriesPer100CarbsLabel,
                fieldKey: const Key('receipt_review_manual_carbs_field'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _numericInputFormatters,
              ),
              const SizedBox(height: AppSpacing.md),
              _ManualProductTextField(
                name: _ManualProductFormFieldName.sugar,
                controller: sugarController,
                label: l10n.caloriesPer100SugarLabel,
                fieldKey: const Key('receipt_review_manual_sugar_field'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _numericInputFormatters,
              ),
              const SizedBox(height: AppSpacing.md),
              _ManualProductTextField(
                name: _ManualProductFormFieldName.protein,
                controller: proteinController,
                label: l10n.caloriesPer100ProteinLabel,
                fieldKey: const Key('receipt_review_manual_protein_field'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _numericInputFormatters,
              ),
              const SizedBox(height: AppSpacing.md),
              _ManualProductTextField(
                name: _ManualProductFormFieldName.salt,
                controller: saltController,
                label: l10n.caloriesPer100SaltLabel,
                fieldKey: const Key('receipt_review_manual_salt_field'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _numericInputFormatters,
              ),
              const SizedBox(height: AppSpacing.md),
              if (showPolyunsaturatedFatField) ...[
                _ManualProductTextField(
                  name: _ManualProductFormFieldName.polyunsaturatedFat,
                  controller: polyunsaturatedFatController,
                  label: l10n.caloriesPer100PolyunsaturatedFatLabel,
                  fieldKey: const Key(
                    'receipt_review_manual_polyunsaturated_fat_field',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _numericInputFormatters,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (showFiberField) ...[
                _ManualProductTextField(
                  name: _ManualProductFormFieldName.fiber,
                  controller: fiberController,
                  label: l10n.caloriesPer100FiberLabel,
                  fieldKey: const Key('receipt_review_manual_fiber_field'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _numericInputFormatters,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (canAddOptionalNutrition || isAddingOptionalNutrition) ...[
                if (isAddingOptionalNutrition)
                  _OptionalNutritionComposer(
                    valueController: optionalNutritionValueController,
                    selectedUnit: optionalNutritionUnit,
                    selectedType: optionalNutritionType,
                    availableTypes: availableOptionalNutritionTypes,
                    onUnitChanged: onOptionalNutritionUnitChanged,
                    onTypeChanged: onOptionalNutritionTypeChanged,
                    onApply: onApplyOptionalNutrition,
                    onCancel: onCancelOptionalNutrition,
                  )
                else
                  _OptionalNutritionAddRow(
                    label: l10n.inventoryReceiptReviewManualAddNutritionAction,
                    onPressed: onStartAddingOptionalNutrition,
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (showActionSelector) ...[
                _ManualProductActionSelector(
                  selectedAction: selectedAction,
                  onChanged: onActionChanged,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (errorText case final String message) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.error),
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
                      onPressed: isRunningNutritionOcr || !canSave
                          ? null
                          : onSave,
                      child: Text(
                        l10n.inventoryReceiptReviewManualDataSaveAction,
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

class _ManualProductSearchShell extends StatelessWidget {
  const _ManualProductSearchShell({
    required this.title,
    required this.searchBar,
    required this.body,
    required this.onClose,
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
            _ManualProductDialogHeader(title: title, onClose: onClose),
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

class _ManualProductDialogHeader extends StatelessWidget {
  const _ManualProductDialogHeader({
    required this.title,
    required this.onClose,
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

class _ManualProductActionSelector extends StatelessWidget {
  const _ManualProductActionSelector({
    required this.selectedAction,
    this.onChanged,
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

class _OptionalNutritionAddRow extends StatelessWidget {
  const _OptionalNutritionAddRow({
    required this.label,
    required this.onPressed,
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

class _OptionalNutritionComposer extends StatelessWidget {
  const _OptionalNutritionComposer({
    required this.valueController,
    required this.selectedUnit,
    required this.selectedType,
    required this.availableTypes,
    required this.onUnitChanged,
    required this.onTypeChanged,
    required this.onApply,
    required this.onCancel,
  });

  final TextEditingController valueController;
  final InventoryAmountUnit selectedUnit;
  final InventoryReceiptOptionalNutritionType? selectedType;
  final List<InventoryReceiptOptionalNutritionType> availableTypes;
  final ValueChanged<InventoryAmountUnit> onUnitChanged;
  final ValueChanged<InventoryReceiptOptionalNutritionType> onTypeChanged;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canApply =
        parseManualProductDouble(valueController.text) != null &&
        selectedType != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ManualProductTextField(
          name: _ManualProductFormFieldName.optionalNutritionValue,
          controller: valueController,
          label: l10n.inventoryReceiptReviewManualNutritionValueLabel,
          fieldKey: const Key(
            'receipt_review_manual_optional_nutrition_value_field',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _numericInputFormatters,
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
                name: _ManualProductFormFieldName.optionalNutritionUnit,
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
                onChanged: (value) {
                  if (value != null) {
                    onUnitChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: FormBuilderDropdown<InventoryReceiptOptionalNutritionType>(
                key: const Key(
                  'receipt_review_manual_optional_nutrition_type_field',
                ),
                name: _ManualProductFormFieldName.optionalNutritionType,
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
                onChanged: (value) {
                  if (value != null) {
                    onTypeChanged(value);
                  }
                },
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

class _ManualProductWeightFields extends StatelessWidget {
  const _ManualProductWeightFields({
    required this.amountController,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.amountFieldKey,
    required this.unitFieldKey,
    required this.amountLabel,
  });

  final TextEditingController amountController;
  final InventoryAmountUnit selectedUnit;
  final ValueChanged<InventoryAmountUnit> onUnitChanged;
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
          child: _ManualProductTextField(
            name: _ManualProductFormFieldName.weightAmount,
            controller: amountController,
            label: amountLabel,
            fieldKey: amountFieldKey,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _numericInputFormatters,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: FormBuilderDropdown<InventoryAmountUnit>(
            key: unitFieldKey,
            name: _ManualProductFormFieldName.weightUnit,
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

class _ManualProductTextField extends StatelessWidget {
  const _ManualProductTextField({
    required this.name,
    required this.controller,
    required this.label,
    required this.fieldKey,
    required this.keyboardType,
    this.inputFormatters,
  });

  final String name;
  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      key: fieldKey,
      name: name,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ManualProductSearchResults extends StatelessWidget {
  const _ManualProductSearchResults({
    required this.results,
    required this.onSelect,
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
              final showsActionButtons =
                  onStoreSelect != null && onEatSelect != null;
              return InventoryProductCandidateTile(
                key: Key('receipt_review_manual_search_result_${result.code}'),
                name: result.name,
                brand: result.brand,
                imageUrl: result.imageUrl,
                packageWeight: result.packageWeight,
                nutrition: result.nutrition,
                onTap: () => onSelect(result),
                trailing: showsActionButtons
                    ? _ManualProductSearchActions(
                        result: result,
                        onStore: onStoreSelect!,
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
    required this.onStore,
    required this.onEat,
  });

  final OffProductSearchResult result;
  final ValueChanged<OffProductSearchResult> onStore;
  final ValueChanged<OffProductSearchResult> onEat;

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
      onInventory: () => onStore(result),
      onEat: () => onEat(result),
    );
  }
}

class _ManualProductRecentItems extends StatelessWidget {
  const _ManualProductRecentItems({
    required this.items,
    required this.onSelect,
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
                  final showsActionButtons =
                      onStoreSelect != null && onEatSelect != null;
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
                    trailing: showsActionButtons
                        ? InventoryProductCandidateActions(
                            inventoryLabel:
                                l10n.inventoryManualAddResultActionInventory,
                            eatLabel: l10n.inventoryManualAddResultActionEat,
                            inventoryButtonKey: inventoryButtonKey,
                            eatButtonKey: eatButtonKey,
                            onInventory: () => onStoreSelect!(item),
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
