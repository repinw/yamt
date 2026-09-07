import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_eat_now_nutrition.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Replaces text in [controller] with [nextText] while preserving selection.
void replaceControllerText(
  TextEditingController controller,
  String nextText, {
  bool collapseSelectionToEnd = false,
}) {
  if (controller.text == nextText) {
    return;
  }

  final selection = collapseSelectionToEnd
      ? TextSelection.collapsed(offset: nextText.length)
      : clampTextSelection(controller.selection, nextText.length);

  controller.value = TextEditingValue(
    text: nextText,
    selection: selection,
  );
}

/// Clamps [selection] offsets to [textLength].
TextSelection clampTextSelection(TextSelection selection, int textLength) {
  final baseOffset = selection.baseOffset.clamp(0, textLength);
  final extentOffset = selection.extentOffset.clamp(0, textLength);
  return TextSelection(
    baseOffset: baseOffset,
    extentOffset: extentOffset,
    affinity: selection.affinity,
    isDirectional: selection.isDirectional,
  );
}

/// Checks whether [state] or [config] satisfies nutritional values for eat now.
bool canEatNow({
  required InventoryReceiptManualProductState state,
  required InventoryReceiptManualProductConfig config,
}) {
  if (state.hasNutritionInput) {
    return true;
  }
  if (state.selectedProduct?.nutrition?.hasAnyNutritionValue == true) {
    return true;
  }
  if (config.selectedProduct?.nutrition?.hasAnyNutritionValue == true) {
    return true;
  }
  return config.item.nutrition?.hasAnyNutritionValue == true;
}

/// Checks whether the form can currently be saved.
bool canSaveManualProduct({
  required InventoryReceiptManualProductState state,
  required InventoryReceiptManualProductAction selectedAction,
  required InventoryReceiptManualProductConfig config,
}) {
  if (!state.hasBarcode && !state.hasNutritionInput) {
    return false;
  }
  if (selectedAction == InventoryReceiptManualProductAction.eatNow) {
    return canEatNow(state: state, config: config);
  }
  return state.hasPackageWeightInput;
}

/// Builds an [InventoryReceiptManualProductResult] from a save [payload].
InventoryReceiptManualProductResult buildSaveProductResult({
  required InventoryReceiptManualProductSavePayload payload,
  required InventoryReceiptManualProductAction action,
}) {
  return InventoryReceiptManualProductResult(
    item: payload.item,
    action: action,
    selectedProduct: payload.selectedProduct,
    selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
    requiresGlobalPersistence: payload.requiresGlobalPersistence,
    globalPackageWeight: payload.globalPackageWeight,
  );
}

/// Formats localized error message for [error].
String? resolveManualProductErrorText(
  AppLocalizations l10n,
  InventoryReceiptManualProductError? error,
) {
  return switch (error) {
    null => null,
    InventoryReceiptManualProductError.requiredProductOrNutrition =>
      l10n.inventoryReceiptReviewManualDataRequired,
    InventoryReceiptManualProductError.requiredPackageWeight =>
      '${l10n.inventoryManualAddPackageSizeLabel}: '
          '${l10n.caloriesRequiredField}',
  };
}

/// Builds a direct eat result from an [OffProductSearchResult] if possible.
InventoryReceiptManualProductResult? tryBuildDirectEatResultFromSearchResult({
  required OffProductSearchResult product,
  required InventoryReceiptManualProductController controller,
}) {
  final payload = controller.buildDirectSearchResultPayload(
    product: product,
    action: InventoryReceiptManualProductAction.eatNow,
  );
  if (payload == null) {
    return null;
  }
  return InventoryReceiptManualProductResult(
    item: payload.item,
    action: InventoryReceiptManualProductAction.eatNow,
    selectedProduct: payload.selectedProduct,
    selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
    requiresGlobalPersistence: payload.requiresGlobalPersistence,
    globalPackageWeight: payload.globalPackageWeight,
  );
}

/// Builds a direct eat result from an [InventoryItem] if possible.
InventoryReceiptManualProductResult? tryBuildDirectEatResultFromInventoryItem({
  required InventoryItem item,
  required String? selectedGlobalFoodItemId,
  required String? globalPackageWeight,
}) {
  if (!hasRequiredEatNowNutrition(item.nutrition)) {
    return null;
  }
  return InventoryReceiptManualProductResult(
    item: item,
    action: InventoryReceiptManualProductAction.eatNow,
    selectedGlobalFoodItemId: selectedGlobalFoodItemId,
    requiresGlobalPersistence: false,
    globalPackageWeight: globalPackageWeight,
  );
}

/// Builds preview data from [controller].
InventoryReceiptManualProductPreviewData? buildEditorPreviewData(
  InventoryReceiptManualProductController controller,
) {
  final preview = controller.buildPreviewData();
  if (preview == null) {
    return null;
  }
  return InventoryReceiptManualProductPreviewData(
    imageUrl: preview.imageUrl,
    name: preview.name,
    brand: preview.brand,
    weight: preview.weight,
  );
}

/// Validates, builds payload, and saves the manual product.
Future<void> executeEditorSave({
  required WidgetRef ref,
  required InventoryReceiptManualProductConfig config,
  required InventoryReceiptManualProductController controller,
  required InventoryReceiptManualProductAction selectedAction,
  required bool closeCurrentEditorOnSave,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
}) async {
  final provider = inventoryReceiptManualProductControllerProvider(config);
  final state = ref.read(provider);
  if (state.isRunningNutritionOcr ||
      !canSaveManualProduct(
        state: state,
        selectedAction: selectedAction,
        config: config,
      )) {
    return;
  }
  final payload = controller.buildSavePayload(action: selectedAction);
  if (payload == null) {
    return;
  }

  final result = buildSaveProductResult(
    payload: payload,
    action: selectedAction,
  );
  if (closeCurrentEditorOnSave) {
    onClosePage(result);
    return;
  }
  if (onSaved != null) {
    await onSaved(result);
    return;
  }
  onClosePage(result);
}

/// Triggers OCR scanning of nutrition label on product and shows feedback.
Future<void> scanEditorNutritionLabel({
  required InventoryReceiptManualProductController controller,
  required BuildContext context,
  required void Function(String message) onShowSnackBar,
}) async {
  final outcome = await controller.scanNutritionLabel();
  if (!context.mounted) {
    return;
  }
  final l10n = AppLocalizations.of(context)!;
  switch (outcome) {
    case InventoryReceiptManualProductNutritionScanOutcome.applied:
    case InventoryReceiptManualProductNutritionScanOutcome.canceled:
    case InventoryReceiptManualProductNutritionScanOutcome.missingBarcode:
      return;
    case InventoryReceiptManualProductNutritionScanOutcome.failed:
      onShowSnackBar(l10n.caloriesOcrFailed);
    case InventoryReceiptManualProductNutritionScanOutcome.appCheckThrottled:
      onShowSnackBar(l10n.caloriesOcrAppCheckThrottled);
  }
}
