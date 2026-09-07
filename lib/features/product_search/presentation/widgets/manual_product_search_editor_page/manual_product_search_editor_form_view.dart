import 'package:flutter/material.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_support.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Form view displaying search, product details, and save actions.
class ManualProductSearchEditorFormView extends StatelessWidget {
  /// Creates the editor form view.
  const ManualProductSearchEditorFormView({
    required this.state,
    required this.controller,
    required this.searchController,
    required this.voiceSearchController,
    required this.voiceSearchService,
    required this.quickEatConfig,
    required this.selectedAction,
    required this.showActionSelector,
    required this.showEatImmediatelyOption,
    required this.autofocusSearch,
    required this.startVoiceSearchOnMount,
    required this.preview,
    required this.canSave,
    required this.onSearchResultAction,
    required this.onScanBarcode,
    required this.onAiSearchTap,
    required this.onCreateManualDraft,
    required this.onScanNutritionLabel,
    required this.onActionChanged,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  /// Current product search state.
  final InventoryReceiptManualProductState state;

  /// Product search controller.
  final InventoryReceiptManualProductController controller;

  /// Text editing controller for search query.
  final TextEditingController searchController;

  /// Controller for voice search.
  final TextVoiceSearchController voiceSearchController;

  /// Voice search service.
  final VoiceSearchService voiceSearchService;

  /// Quick eat configuration.
  final InventoryManualAddQuickEatConfig quickEatConfig;

  /// Currently chosen save action.
  final InventoryReceiptManualProductAction selectedAction;

  /// Whether the action selector is visible.
  final bool showActionSelector;

  /// Whether the immediate eat action is supported.
  final bool showEatImmediatelyOption;

  /// Whether search autofocus is enabled.
  final bool autofocusSearch;

  /// Whether voice search starts on mount.
  final bool startVoiceSearchOnMount;

  /// Preview data for the selected product.
  final InventoryReceiptManualProductPreviewData? preview;

  /// Whether the product can currently be saved.
  final bool canSave;

  /// Search result action callback.
  final void Function(
    OffProductSearchResult product,
    InventoryReceiptManualProductAction action,
  )
  onSearchResultAction;

  /// Barcode scanning callback.
  final VoidCallback onScanBarcode;

  /// AI search callback.
  final VoidCallback onAiSearchTap;

  /// Manual draft creation callback.
  final VoidCallback onCreateManualDraft;

  /// Nutrition label scan callback.
  final VoidCallback? onScanNutritionLabel;

  /// Action change callback.
  final ValueChanged<InventoryReceiptManualProductAction> onActionChanged;

  /// Cancel callback.
  final VoidCallback onCancel;

  /// Save callback.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: InventoryReceiptManualProductForm(
        title: l10n.inventoryManualAddSearchDialogTitle,
        preview: preview,
        searchController: searchController,
        isSearching: state.isSearching,
        canSave: canSave,
        isRunningNutritionOcr: state.isRunningNutritionOcr,
        nutritionOcrImageBytes: state.nutritionOcrImageBytes,
        autofocusSearch: autofocusSearch,
        showDetails: state.showDetails,
        searchResults: state.searchResults,
        recentItems: const <InventoryItem>[],
        nameText: state.nameText,
        brandText: state.brandText,
        weightAmount: state.weightAmount,
        selectedWeightUnit: state.selectedWeightUnit,
        kcalText: state.kcalText,
        saturatedFatText: state.saturatedFatText,
        polyunsaturatedFatText: state.polyunsaturatedFatText,
        showPolyunsaturatedFatField: state.showPolyunsaturatedFatField,
        fatText: state.fatText,
        carbsText: state.carbsText,
        sugarText: state.sugarText,
        fiberText: state.fiberText,
        showFiberField: state.showFiberField,
        proteinText: state.proteinText,
        saltText: state.saltText,
        canAddOptionalNutrition: state.canAddOptionalNutrition,
        isAddingOptionalNutrition: state.isAddingOptionalNutrition,
        optionalNutritionValueText: state.optionalNutritionValueText,
        optionalNutritionUnit: state.optionalNutritionUnit,
        optionalNutritionType: state.resolvedOptionalNutritionType,
        availableOptionalNutritionTypes: state.availableOptionalNutritionTypes,
        errorText: resolveManualProductErrorText(l10n, state.error),
        onAiSearchTap: onAiSearchTap,
        canCreateManualDraft: state.canCreateManualDraft,
        onCreateManualDraft: onCreateManualDraft,
        showActionSelector:
            showEatImmediatelyOption &&
            showActionSelector &&
            !quickEatConfig.quickEatOnly,
        selectedAction: selectedAction,
        onSearchResultSelected: (product) => onSearchResultAction(
          product,
          quickEatConfig.quickEatOnly
              ? InventoryReceiptManualProductAction.eatNow
              : InventoryReceiptManualProductAction.addToInventory,
        ),
        onSearchResultStoreSelected: showEatImmediatelyOption
            ? quickEatConfig.quickEatOnly
                  ? null
                  : (product) => onSearchResultAction(
                        product,
                        InventoryReceiptManualProductAction.addToInventory,
                      )
            : null,
        onSearchResultEatSelected: showEatImmediatelyOption
            ? (product) => onSearchResultAction(
                  product,
                  InventoryReceiptManualProductAction.eatNow,
                )
            : null,
        onRecentItemSelected: controller.applyRecentItem,
        onSearchChanged: controller.updateSearchQuery,
        voiceSearchService: voiceSearchService,
        voiceSearchController: voiceSearchController,
        startVoiceSearchOnMount: startVoiceSearchOnMount,
        onScanBarcode: onScanBarcode,
        onNameChanged: controller.updateNameText,
        onBrandChanged: controller.updateBrandText,
        onWeightAmountChanged: controller.updateWeightAmount,
        onWeightUnitChanged: controller.updateWeightUnit,
        onKcalChanged: controller.updateKcalText,
        onFatChanged: controller.updateFatText,
        onSaturatedFatChanged: controller.updateSaturatedFatText,
        onCarbsChanged: controller.updateCarbsText,
        onSugarChanged: controller.updateSugarText,
        onProteinChanged: controller.updateProteinText,
        onSaltChanged: controller.updateSaltText,
        onPolyunsaturatedFatChanged: controller.updatePolyunsaturatedFatText,
        onFiberChanged: controller.updateFiberText,
        onScanNutritionLabel: onScanNutritionLabel,
        onStartAddingOptionalNutrition: controller.startAddingOptionalNutrition,
        onOptionalNutritionValueChanged:
            controller.updateOptionalNutritionValueText,
        onOptionalNutritionUnitChanged: controller.updateOptionalNutritionUnit,
        onOptionalNutritionTypeChanged: controller.updateOptionalNutritionType,
        onApplyOptionalNutrition: controller.applyOptionalNutrition,
        onCancelOptionalNutrition: controller.cancelAddingOptionalNutrition,
        onActionChanged: onActionChanged,
        onCancel: onCancel,
        onSave: onSave,
      ),
    );
  }
}
