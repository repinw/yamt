import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_barcode_coordinator.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Launches the barcode scanner flow and dispatches candidate actions.
Future<void> launchEditorBarcodeScanner({
  required BuildContext context,
  required InventoryManualAddQuickEatConfig quickEatConfig,
  required InventoryReceiptManualProductConfig config,
  required InventoryReceiptManualProductController controller,
  required bool showEatImmediatelyOption,
  required bool autofocusSearch,
  required void Function(
    InventoryReceiptManualProductAction action,
    VoidCallback apply,
  )
  onApplyAction,
  required void Function(String message) onShowSnackBar,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
}) {
  return openEditorBarcodeScanner(
    context: context,
    quickEatConfig: quickEatConfig,
    config: config,
    controller: controller,
    showEatImmediatelyOption: showEatImmediatelyOption,
    autofocusSearch: autofocusSearch,
    onDirectComplete: onClosePage,
    onApplyScannedProduct: (product, action) =>
        onApplyAction(action, () => controller.applyScannedProduct(product)),
    onApplyScannedInventoryItem: (item, action) =>
        onApplyAction(action, () => controller.applyRecentItem(item)),
    onApplyScannedBarcodeOnly: controller.applyScannedBarcodeOnly,
    onShowSnackBar: onShowSnackBar,
    onSaved: onSaved,
    onClosePage: onClosePage,
  );
}

/// Shows an editor message on the nearest ScaffoldMessenger.
void showEditorSnackBar(
  BuildContext context,
  String message, {
  required AppSnackBarTone tone,
  AppSnackBarAction? action,
}) {
  ScaffoldMessenger.of(context)
      .showAppSnackBar(message, tone: tone, action: action);
}

/// Builds the optional initial info action (e.g. nutrition label OCR scan).
AppSnackBarAction? buildEditorInitialInfoAction({
  required BuildContext context,
  required bool canScanNutritionLabel,
  required VoidCallback onScanNutritionLabel,
}) {
  if (!canScanNutritionLabel) {
    return null;
  }
  return (
    label: AppLocalizations.of(context)!.caloriesBarcodeNotFoundOcrAction,
    onPressed: onScanNutritionLabel,
  );
}

/// Schedules initial info message display on next frame if present.
void scheduleEditorInitialInfoMessage({
  required String? message,
  required bool Function() isMounted,
  required BuildContext context,
  AppSnackBarAction? Function()? actionBuilder,
}) {
  if (message == null) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMounted()) {
      showEditorSnackBar(
        context,
        message,
        tone: AppSnackBarTone.info,
        action: actionBuilder?.call(),
      );
    }
  });
}

/// Schedules applying the initial recent item on next frame if present.
void scheduleEditorInitialRecentItem({
  required InventoryItem? recentItem,
  required bool Function() isMounted,
  required void Function(InventoryItem item) onApplyRecentItem,
}) {
  if (recentItem == null) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMounted()) {
      onApplyRecentItem(recentItem);
    }
  });
}
