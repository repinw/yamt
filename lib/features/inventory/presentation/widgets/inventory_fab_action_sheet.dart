import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_fab_action_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Bottom sheet with inventory add actions.
class InventoryFabActionSheet extends StatelessWidget {
  /// Creates inventory action sheet.
  const InventoryFabActionSheet({
    required this.isCameraEnabled,
    required this.onProductSearchHub,
    required this.onManualSearch,
    required this.onBarcodeScan,
    required this.onAiSuggestion,
    required this.onUploadFile,
    required this.onScanCamera,
    super.key,
  });

  /// Whether camera action can be used.
  final bool isCameraEnabled;

  /// Opens unified product search hub.
  final VoidCallback onProductSearchHub;

  /// Opens manual product search.
  final VoidCallback onManualSearch;

  /// Starts barcode scan flow.
  final VoidCallback onBarcodeScan;

  /// Starts AI suggestion flow.
  final VoidCallback onAiSuggestion;

  /// Opens image or PDF upload flow.
  final VoidCallback onUploadFile;

  /// Starts camera capture flow.
  final VoidCallback onScanCamera;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InventoryFabActionTile(
                  key: const Key('inventory_action_product_search_hub_fab'),
                  icon: Icons.add_shopping_cart_rounded,
                  label: l10n.productSearchHubTitle,
                  onPressed: onProductSearchHub,
                ),
                InventoryFabActionTile(
                  key: const Key('inventory_action_manual_search_fab'),
                  icon: Icons.search_rounded,
                  label: l10n.inventoryActionManualSearch,
                  onPressed: onManualSearch,
                ),
                InventoryFabActionTile(
                  key: const Key('inventory_action_barcode_fab'),
                  icon: Icons.qr_code_scanner_rounded,
                  label: l10n.diaryQuickEatSourceBarcode,
                  onPressed: onBarcodeScan,
                ),
                InventoryFabActionTile(
                  key: const Key('inventory_action_ai_suggestion_fab'),
                  icon: Icons.auto_awesome_rounded,
                  label: l10n.inventoryActionAiSuggestion,
                  onPressed: onAiSuggestion,
                ),
                InventoryFabActionTile(
                  key: const Key('inventory_action_upload_image_pdf_fab'),
                  icon: Icons.upload_file_rounded,
                  label: l10n.inventoryActionUploadImagePdf,
                  onPressed: onUploadFile,
                ),
                InventoryFabActionTile(
                  key: const Key('inventory_action_camera_fab'),
                  icon: Icons.photo_camera_rounded,
                  label: l10n.inventoryActionCamera,
                  subtitle: isCameraEnabled
                      ? null
                      : l10n.inventoryActionCameraUnsupported,
                  onPressed: isCameraEnabled ? onScanCamera : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
