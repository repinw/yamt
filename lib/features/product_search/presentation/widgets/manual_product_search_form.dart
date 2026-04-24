import 'package:flutter/material.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form_components.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_controller.dart';

export 'manual_product_search_form_components.dart'
    show InventoryReceiptManualProductPreviewData;

/// Defines inventory receipt manual product launcher content.
class InventoryReceiptManualProductLauncherContent extends StatelessWidget {
  /// The inventory receipt manual product launcher content.
  const InventoryReceiptManualProductLauncherContent({
    required this.title,
    required this.searchController,
    required this.recentItems,
    required this.onClose,
    required this.onAiSearchTap,
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

  /// Open AI search page.
  final VoidCallback onAiSearchTap;

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
    return ManualProductSearchShell(
      title: title,
      onClose: onClose,
      searchBar: ManualProductSearchToolbar(
        searchController: searchController,
        clearButtonKey: const Key(
          'receipt_review_manual_launcher_search_clear_button',
        ),
        fieldKey: const Key('receipt_review_manual_launcher_search_field'),
        readOnly: true,
        onTap: onSearchTap,
        onVoiceSearchPressed: onVoiceSearchTap,
        onAiSearchTap: onAiSearchTap,
        onScanBarcode: onScanBarcode,
      ),
      body: ManualProductRecentItems(
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
    required this.isSearching,
    required this.canSave,
    required this.isRunningNutritionOcr,
    required this.showDetails,
    required this.searchResults,
    required this.recentItems,
    required this.nameText,
    required this.brandText,
    required this.weightAmount,
    required this.selectedWeightUnit,
    required this.kcalText,
    required this.saturatedFatText,
    required this.polyunsaturatedFatText,
    required this.showPolyunsaturatedFatField,
    required this.fatText,
    required this.carbsText,
    required this.sugarText,
    required this.fiberText,
    required this.showFiberField,
    required this.proteinText,
    required this.saltText,
    required this.canAddOptionalNutrition,
    required this.isAddingOptionalNutrition,
    required this.optionalNutritionValueText,
    required this.optionalNutritionUnit,
    required this.optionalNutritionType,
    required this.availableOptionalNutritionTypes,
    required this.preview,
    required this.errorText,
    required this.onAiSearchTap,
    required this.showActionSelector,
    required this.selectedAction,
    required this.onSearchResultSelected,
    required this.onRecentItemSelected,
    required this.onScanBarcode,
    required this.onNameChanged,
    required this.onBrandChanged,
    required this.onWeightAmountChanged,
    required this.onWeightUnitChanged,
    required this.onKcalChanged,
    required this.onFatChanged,
    required this.onSaturatedFatChanged,
    required this.onCarbsChanged,
    required this.onSugarChanged,
    required this.onProteinChanged,
    required this.onSaltChanged,
    required this.onPolyunsaturatedFatChanged,
    required this.onFiberChanged,
    required this.onScanNutritionLabel,
    required this.onStartAddingOptionalNutrition,
    required this.onOptionalNutritionValueChanged,
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

  /// The name text.
  final String nameText;

  /// The brand text.
  final String brandText;

  /// The weight amount text.
  final String weightAmount;

  /// The selected weight unit.
  final InventoryAmountUnit selectedWeightUnit;

  /// The kcal text.
  final String kcalText;

  /// The saturated fat text.
  final String saturatedFatText;

  /// The polyunsaturated fat text.
  final String polyunsaturatedFatText;

  /// The show polyunsaturated fat field.
  final bool showPolyunsaturatedFatField;

  /// The fat text.
  final String fatText;

  /// The carbs text.
  final String carbsText;

  /// The sugar text.
  final String sugarText;

  /// The fiber text.
  final String fiberText;

  /// The show fiber field.
  final bool showFiberField;

  /// The protein text.
  final String proteinText;

  /// The salt text.
  final String saltText;

  /// Whether add optional nutrition.
  final bool canAddOptionalNutrition;

  /// Whether adding optional nutrition.
  final bool isAddingOptionalNutrition;

  /// The optional nutrition value text.
  final String optionalNutritionValueText;

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

  /// Open AI search page.
  final VoidCallback onAiSearchTap;

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

  /// The on name changed.
  final ValueChanged<String> onNameChanged;

  /// The on brand changed.
  final ValueChanged<String> onBrandChanged;

  /// The on search changed.
  final ValueChanged<String>? onSearchChanged;

  /// The on weight amount changed.
  final ValueChanged<String> onWeightAmountChanged;

  /// The voice search service.
  final VoiceSearchService? voiceSearchService;

  /// The voice search controller.
  final TextVoiceSearchController? voiceSearchController;

  /// The start voice search on mount.
  final bool startVoiceSearchOnMount;

  /// The on weight unit changed.
  final ValueChanged<InventoryAmountUnit> onWeightUnitChanged;

  /// The on kcal changed.
  final ValueChanged<String> onKcalChanged;

  /// The on fat changed.
  final ValueChanged<String> onFatChanged;

  /// The on saturated fat changed.
  final ValueChanged<String> onSaturatedFatChanged;

  /// The on carbs changed.
  final ValueChanged<String> onCarbsChanged;

  /// The on sugar changed.
  final ValueChanged<String> onSugarChanged;

  /// The on protein changed.
  final ValueChanged<String> onProteinChanged;

  /// The on salt changed.
  final ValueChanged<String> onSaltChanged;

  /// The on polyunsaturated fat changed.
  final ValueChanged<String> onPolyunsaturatedFatChanged;

  /// The on fiber changed.
  final ValueChanged<String> onFiberChanged;

  /// The on scan nutrition label.
  final VoidCallback? onScanNutritionLabel;

  /// The on start adding optional nutrition.
  final VoidCallback onStartAddingOptionalNutrition;

  /// The on optional nutrition value changed.
  final ValueChanged<String> onOptionalNutritionValueChanged;

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
    return ManualProductSearchShell(
      title: title,
      onClose: onCancel,
      searchBar: ManualProductSearchToolbar(
        searchController: searchController,
        clearButtonKey: const Key('receipt_review_manual_search_clear_button'),
        fieldKey: const Key('receipt_review_manual_search_field'),
        isSearching: isSearching,
        autofocus: autofocusSearch,
        onChanged: onSearchChanged,
        voiceSearchService: voiceSearchService,
        voiceSearchController: voiceSearchController,
        startVoiceSearchOnMount: startVoiceSearchOnMount,
        onAiSearchTap: onAiSearchTap,
        onScanBarcode: onScanBarcode,
      ),
      body: ManualProductDetailsForm(
        searchResults: searchResults,
        recentItems: recentItems,
        showDetails: showDetails,
        preview: preview,
        nameText: nameText,
        brandText: brandText,
        weightAmount: weightAmount,
        selectedWeightUnit: selectedWeightUnit,
        kcalText: kcalText,
        saturatedFatText: saturatedFatText,
        polyunsaturatedFatText: polyunsaturatedFatText,
        showPolyunsaturatedFatField: showPolyunsaturatedFatField,
        fatText: fatText,
        carbsText: carbsText,
        sugarText: sugarText,
        fiberText: fiberText,
        showFiberField: showFiberField,
        proteinText: proteinText,
        saltText: saltText,
        canAddOptionalNutrition: canAddOptionalNutrition,
        isAddingOptionalNutrition: isAddingOptionalNutrition,
        optionalNutritionValueText: optionalNutritionValueText,
        optionalNutritionUnit: optionalNutritionUnit,
        optionalNutritionType: optionalNutritionType,
        availableOptionalNutritionTypes: availableOptionalNutritionTypes,
        errorText: errorText,
        showActionSelector: showActionSelector,
        selectedAction: selectedAction,
        canSave: canSave,
        isRunningNutritionOcr: isRunningNutritionOcr,
        onSearchResultSelected: onSearchResultSelected,
        onSearchResultStoreSelected: onSearchResultStoreSelected,
        onSearchResultEatSelected: onSearchResultEatSelected,
        onRecentItemSelected: onRecentItemSelected,
        onNameChanged: onNameChanged,
        onBrandChanged: onBrandChanged,
        onWeightAmountChanged: onWeightAmountChanged,
        onWeightUnitChanged: onWeightUnitChanged,
        onScanNutritionLabel: onScanNutritionLabel,
        onKcalChanged: onKcalChanged,
        onFatChanged: onFatChanged,
        onSaturatedFatChanged: onSaturatedFatChanged,
        onCarbsChanged: onCarbsChanged,
        onSugarChanged: onSugarChanged,
        onProteinChanged: onProteinChanged,
        onSaltChanged: onSaltChanged,
        onPolyunsaturatedFatChanged: onPolyunsaturatedFatChanged,
        onFiberChanged: onFiberChanged,
        onStartAddingOptionalNutrition: onStartAddingOptionalNutrition,
        onOptionalNutritionValueChanged: onOptionalNutritionValueChanged,
        onOptionalNutritionUnitChanged: onOptionalNutritionUnitChanged,
        onOptionalNutritionTypeChanged: onOptionalNutritionTypeChanged,
        onApplyOptionalNutrition: onApplyOptionalNutrition,
        onCancelOptionalNutrition: onCancelOptionalNutrition,
        onActionChanged: onActionChanged,
        onCancel: onCancel,
        onSave: onSave,
      ),
    );
  }
}
