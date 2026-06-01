import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/home/widgets/inventory_action_sheet_flow.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_fab_menu_action.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Runs one expanded inventory FAB action.
typedef InventoryFabActionRunner =
    void Function(Future<void> Function() action);

/// Builds expanded inventory FAB actions.
@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
List<Widget> buildInventoryExpandedFabActions({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required bool isCameraEnabled,
  required InventoryFabActionRunner runAction,
}) {
  return [
    InventoryFabMenuAction(
      key: const Key('inventory_action_product_search_hub_fab'),
      heroTag: 'inventory_action_product_search_hub_fab',
      icon: Icons.add_shopping_cart_rounded,
      label: l10n.productSearchHubTitle,
      onPressed: () => runAction(
        () => InventoryActionSheetFlow.openProductSearchHub(
          context: context,
        ),
      ),
    ),
    InventoryFabMenuAction(
      key: const Key('inventory_action_manual_search_fab'),
      heroTag: 'inventory_action_manual_search_fab',
      icon: Icons.search_rounded,
      label: l10n.inventoryActionManualSearch,
      onPressed: () => runAction(
        () => InventoryActionSheetFlow.openManualSearch(
          context: context,
          l10n: l10n,
        ),
      ),
    ),
    InventoryFabMenuAction(
      key: const Key('inventory_action_barcode_fab'),
      heroTag: 'inventory_action_barcode_fab',
      icon: Icons.qr_code_scanner_rounded,
      label: l10n.diaryQuickEatSourceBarcode,
      onPressed: () => runAction(
        () => InventoryActionSheetFlow.openBarcodeScanner(
          context: context,
          l10n: l10n,
        ),
      ),
    ),
    InventoryFabMenuAction(
      key: const Key('inventory_action_ai_suggestion_fab'),
      heroTag: 'inventory_action_ai_suggestion_fab',
      icon: Icons.auto_awesome_rounded,
      label: l10n.inventoryActionAiSuggestion,
      onPressed: () => runAction(
        () => InventoryActionSheetFlow.openAiSuggestion(
          context: context,
          l10n: l10n,
        ),
      ),
    ),
    InventoryFabMenuAction(
      key: const Key('inventory_action_upload_image_pdf_fab'),
      heroTag: 'inventory_action_upload_image_pdf_fab',
      icon: Icons.upload_file_rounded,
      label: l10n.inventoryActionUploadImagePdf,
      onPressed: () => runAction(
        () => InventoryActionSheetFlow.uploadFile(
          context: context,
          ref: ref,
          l10n: l10n,
        ),
      ),
    ),
    InventoryFabMenuAction(
      key: const Key('inventory_action_camera_fab'),
      heroTag: 'inventory_action_camera_fab',
      icon: Icons.photo_camera_rounded,
      label: l10n.inventoryActionCamera,
      tooltip: isCameraEnabled
          ? l10n.inventoryActionCamera
          : l10n.inventoryActionCameraUnsupported,
      onPressed: isCameraEnabled
          ? () => runAction(
              () => InventoryActionSheetFlow.scanCamera(
                context: context,
                ref: ref,
                l10n: l10n,
              ),
            )
          : null,
    ),
  ];
}
