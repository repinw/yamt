import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/barcode_icon.dart';
import 'package:yamt/core/widgets/home_dock_tool.dart';
import 'package:yamt/core/widgets/home_more_sheet.dart';
import 'package:yamt/features/home/widgets/inventory_action_sheet_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Height of the dock, so the shell keeps snack bars above it.
const double inventoryDockHeight = homeShellDockHeight;

/// Add actions docked at the bottom of the Vorrat tab: the lime "Hinzufügen"
/// with the less frequent ways to add, and tonal tools for the receipt and
/// the barcode.
class InventoryDock extends ConsumerWidget {
  /// Creates the dock.
  const new({super.key});

  /// Key of the "Hinzufügen" button.
  static const addKey = ValueKey<String>('inventory-dock-add');

  /// Key of the barcode tool.
  static const barcodeKey = ValueKey<String>('inventory-dock-barcode');

  /// Key of the receipt tool.
  static const receiptKey = ValueKey<String>('inventory-dock-receipt');

  /// Key of the add sheet entry that opens the product search.
  static const manualSearchKey = ValueKey<String>(
    'inventory-add-manual-search',
  );

  /// Key of the add sheet entry that opens the AI estimate.
  static const aiKey = ValueKey<String>('inventory-add-ai');

  /// Key of the add sheet entry that opens the editor for an own product.
  static const createKey = ValueKey<String>('inventory-add-create');

  /// Key of the receipt sheet entry that takes a photo.
  static const receiptPhotoKey = ValueKey<String>('inventory-receipt-photo');

  /// Key of the receipt sheet entry that uploads an image or PDF.
  static const receiptUploadKey = ValueKey<String>('inventory-receipt-upload');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          spacing: AppSpacing.xs,
          children: [
            Expanded(
              child: SizedBox(
                height: AppSizes.headerTool,
                child: FilledButton.icon(
                  key: addKey,
                  onPressed: () => _showAddSheet(context, ref, l10n),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.inventoryDockAddAction),
                ),
              ),
            ),
            HomeDockTool(
              key: receiptKey,
              symbol: const Icon(Icons.receipt_long_rounded),
              label: l10n.inventoryDockReceiptTool,
              onPressed: () => _openReceipt(context, ref, l10n),
            ),
            HomeDockTool(
              key: barcodeKey,
              symbol: const BarcodeIcon(),
              label: l10n.diaryQuickEatSourceBarcode,
              onPressed: () => unawaited(
                InventoryActionSheetFlow.openBarcodeScanner(
                  context: context,
                  l10n: l10n,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    unawaited(
      showHomeMoreSheet(
        context,
        sections: [
          HomeMoreSection(
            title: l10n.inventoryDockAddAction,
            entries: [
              HomeMoreEntry(
                key: manualSearchKey,
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
              HomeMoreEntry(
                key: aiKey,
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
              HomeMoreEntry(
                key: createKey,
                icon: Icons.edit_note_rounded,
                title: l10n.productSearchHubCreateOwnAction,
                description: l10n.inventoryAddCreateDescription,
                onSelected: () => unawaited(
                  InventoryActionSheetFlow.openCreate(
                    context: context,
                    l10n: l10n,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Offers a photo or an uploaded image or PDF of the receipt. Without a
  /// camera the upload is the only way, so it starts right away.
  void _openReceipt(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    void upload() => unawaited(
      InventoryActionSheetFlow.uploadFile(
        context: context,
        ref: ref,
        l10n: l10n,
      ),
    );

    if (!InventoryActionSheetFlow.canPhotographReceipt(ref)) {
      upload();
      return;
    }
    unawaited(
      showHomeMoreSheet(
        context,
        sections: [
          HomeMoreSection(
            title: l10n.inventoryDockReceiptTool,
            entries: [
              HomeMoreEntry(
                key: receiptPhotoKey,
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
              HomeMoreEntry(
                key: receiptUploadKey,
                icon: Icons.upload_file_rounded,
                title: l10n.inventoryActionUploadImagePdf,
                description: l10n.inventoryAddUploadDescription,
                onSelected: upload,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
