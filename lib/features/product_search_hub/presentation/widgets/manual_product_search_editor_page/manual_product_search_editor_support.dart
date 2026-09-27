import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_eat_now_nutrition.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_photo_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Checks whether the form can currently be saved.
bool canSaveManualProduct({
  required InventoryReceiptManualProductState state,
  required InventoryReceiptManualProductAction selectedAction,
}) {
  if (!state.hasRequiredFields || !state.hasBarcodeDecision) {
    return false;
  }
  if (selectedAction == InventoryReceiptManualProductAction.eatNow) {
    return true;
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

/// Validates, stores the package photos, builds payload, and saves the
/// manual product.
///
/// A failed photo upload does not stop the save: the product is saved
/// without its photos and [onPhotosNotSaved] tells the user.
Future<void> executeEditorSave({
  required WidgetRef ref,
  required InventoryReceiptManualProductConfig config,
  required InventoryReceiptManualProductController controller,
  required InventoryReceiptManualProductAction selectedAction,
  required bool Function() isMounted,
  required VoidCallback onPhotosNotSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
}) async {
  final state = ref.read(
    inventoryReceiptManualProductControllerProvider(config),
  );
  final photos = manualProductPhotoControllerProvider(config);
  if (ref.read(photos).isBusy ||
      !canSaveManualProduct(state: state, selectedAction: selectedAction)) {
    return;
  }
  String? photoImageUrl;
  try {
    photoImageUrl = await ref
        .read(photos.notifier)
        .savePhotos(barcode: state.barcode, name: state.nameText.trim());
  } on Object catch (error, stackTrace) {
    log(
      'Storing the package photos failed; saving without them.',
      name: 'ManualProductEditor',
      error: error,
      stackTrace: stackTrace,
    );
    if (isMounted()) onPhotosNotSaved();
  }
  if (!isMounted()) return;
  final payload = controller.buildSavePayload(
    action: selectedAction,
    photoImageUrl: photoImageUrl,
  );
  if (payload == null) {
    return;
  }

  final result = buildSaveProductResult(
    payload: payload,
    action: selectedAction,
  );
  onClosePage(result);
}

/// Takes a photo of the package front and reports problems.
Future<void> takeEditorFrontPhoto({
  required ManualProductPhotoController photos,
  required BuildContext context,
  required void Function(String message, {AppSnackBarAction? action})
  onShowSnackBar,
}) async {
  final outcome = await photos.takeFrontPhoto();
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  void retake() => unawaited(
    takeEditorFrontPhoto(
      photos: photos,
      context: context,
      onShowSnackBar: onShowSnackBar,
    ),
  );
  _showPhotoOutcome(
    outcome,
    l10n: l10n,
    onShowSnackBar: onShowSnackBar,
    retake: retake,
    retakeMessage: l10n.productEditorFrontUnreadable,
    failedMessage: l10n.productEditorFrontFailed,
  );
}

/// Takes a photo of the nutrition table and reports problems.
Future<void> takeEditorNutritionTablePhoto({
  required ManualProductPhotoController photos,
  required BuildContext context,
  required void Function(String message, {AppSnackBarAction? action})
  onShowSnackBar,
}) async {
  final outcome = await photos.takeNutritionTablePhoto();
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  void retake() => unawaited(
    takeEditorNutritionTablePhoto(
      photos: photos,
      context: context,
      onShowSnackBar: onShowSnackBar,
    ),
  );
  _showPhotoOutcome(
    outcome,
    l10n: l10n,
    onShowSnackBar: onShowSnackBar,
    retake: retake,
    retakeMessage: l10n.caloriesOcrRetakePhoto,
    failedMessage: l10n.caloriesOcrFailed,
  );
}

void _showPhotoOutcome(
  ManualProductPhotoOutcome outcome, {
  required AppLocalizations l10n,
  required void Function(String message, {AppSnackBarAction? action})
  onShowSnackBar,
  required VoidCallback retake,
  required String retakeMessage,
  required String failedMessage,
}) {
  final retakeAction = (
    label: l10n.caloriesOcrRetakePhotoAction,
    onPressed: retake,
  );
  switch (outcome) {
    case ManualProductPhotoOutcome.read:
    case ManualProductPhotoOutcome.canceled:
      return;
    case ManualProductPhotoOutcome.cameraUnsupported:
      onShowSnackBar(l10n.productEditorCameraUnsupported);
    case ManualProductPhotoOutcome.notProduct:
      onShowSnackBar(l10n.productEditorFrontNotProduct, action: retakeAction);
    case ManualProductPhotoOutcome.retakePhoto:
      onShowSnackBar(retakeMessage, action: retakeAction);
    case ManualProductPhotoOutcome.appCheckThrottled:
      onShowSnackBar(l10n.caloriesOcrAppCheckThrottled);
    case ManualProductPhotoOutcome.failed:
      onShowSnackBar(failedMessage);
  }
}
