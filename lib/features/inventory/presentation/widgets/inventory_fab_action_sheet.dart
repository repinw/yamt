import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_fab_action_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryFabActionSheet extends StatelessWidget {
  const InventoryFabActionSheet({
    required this.isCameraEnabled,
    required this.onManualSearch,
    required this.onBarcodeScan,
    required this.onAiSuggestion,
    required this.onUploadFile,
    required this.onScanCamera,
  });

  final bool isCameraEnabled;
  final VoidCallback onManualSearch;
  final VoidCallback onBarcodeScan;
  final VoidCallback onAiSuggestion;
  final VoidCallback onUploadFile;
  final VoidCallback onScanCamera;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    );
  }
}
