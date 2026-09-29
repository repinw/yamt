import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/barcode_icon.dart';
import 'package:yamt/core/widgets/home_action_entry.dart';
import 'package:yamt/features/home/widgets/inventory_action_sheet_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Keys of the Vorrat add actions.
abstract final class InventoryAddActionKeys {
  /// Entry that scans a barcode.
  static const barcode = ValueKey<String>('inventory-add-barcode');

  /// Entry that opens the product search.
  static const manualSearch = ValueKey<String>('inventory-add-manual-search');

  /// Entry that opens the AI estimate.
  static const ai = ValueKey<String>('inventory-add-ai');

  /// Entry that opens the editor for an own product.
  static const create = ValueKey<String>('inventory-add-create');

  /// Entry that takes a photo of a receipt.
  static const receiptPhoto = ValueKey<String>('inventory-receipt-photo');

  /// Entry that uploads an image or PDF of a receipt.
  static const receiptUpload = ValueKey<String>('inventory-receipt-upload');
}

/// The ways to add food to the Vorrat: barcode, search, AI, an own product,
/// and a receipt as photo or upload. Without a camera the receipt offers only
/// the upload.
List<HomeActionSection> inventoryAddActions(
  BuildContext context,
  WidgetRef ref,
) {
  final l10n = AppLocalizations.of(context)!;
  return [
    HomeActionSection(
      title: l10n.inventoryDockAddAction,
      entries: [
        HomeActionEntry(
          key: InventoryAddActionKeys.barcode,
          symbol: const BarcodeIcon(),
          title: l10n.diaryQuickEatSourceBarcode,
          description: l10n.inventoryAddBarcodeDescription,
          onSelected: () => unawaited(
            InventoryActionSheetFlow.openBarcodeScanner(
              context: context,
              l10n: l10n,
            ),
          ),
        ),
        HomeActionEntry(
          key: InventoryAddActionKeys.manualSearch,
          icon: Icons.search_rounded,
          title: l10n.inventoryActionManualSearch,
          description: l10n.inventoryAddManualSearchDescription,
          onSelected: () => unawaited(
            InventoryActionSheetFlow.openManualSearch(
              context: context,
              l10n: l10n,
            ),
          ),
        ),
        HomeActionEntry(
          key: InventoryAddActionKeys.ai,
          icon: Icons.auto_awesome_rounded,
          title: l10n.inventoryActionAiSuggestion,
          description: l10n.inventoryAddAiDescription,
          onSelected: () => unawaited(
            InventoryActionSheetFlow.openAiSuggestion(
              context: context,
              l10n: l10n,
            ),
          ),
        ),
        HomeActionEntry(
          key: InventoryAddActionKeys.create,
          icon: Icons.edit_note_rounded,
          title: l10n.productSearchHubCreateOwnAction,
          description: l10n.inventoryAddCreateDescription,
          onSelected: () => unawaited(
            InventoryActionSheetFlow.openCreate(context: context, l10n: l10n),
          ),
        ),
      ],
    ),
    HomeActionSection(
      title: l10n.inventoryDockReceiptTool,
      entries: [
        if (InventoryActionSheetFlow.canPhotographReceipt(ref))
          HomeActionEntry(
            key: InventoryAddActionKeys.receiptPhoto,
            icon: Icons.photo_camera_rounded,
            title: l10n.inventoryReceiptPhotoAction,
            description: l10n.inventoryReceiptPhotoDescription,
            onSelected: () => unawaited(
              InventoryActionSheetFlow.photographReceipt(
                context: context,
                ref: ref,
                l10n: l10n,
              ),
            ),
          ),
        HomeActionEntry(
          key: InventoryAddActionKeys.receiptUpload,
          icon: Icons.upload_file_rounded,
          title: l10n.inventoryActionUploadImagePdf,
          description: l10n.inventoryAddUploadDescription,
          onSelected: () => unawaited(
            InventoryActionSheetFlow.uploadFile(
              context: context,
              ref: ref,
              l10n: l10n,
            ),
          ),
        ),
      ],
    ),
  ];
}
