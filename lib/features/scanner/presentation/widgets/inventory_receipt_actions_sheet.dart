import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory receipt actions sheet.
class InventoryReceiptActionsSheet extends StatelessWidget {
  /// The inventory receipt actions sheet.
  const InventoryReceiptActionsSheet({
    required this.isCameraEnabled, required this.onManualAddTap, required this.onScanCameraTap, required this.onUploadFileTap, super.key,
  });

  /// Whether camera enabled.
  final bool isCameraEnabled;

  /// The on manual add tap.
  final VoidCallback onManualAddTap;

  /// The on scan camera tap.
  final VoidCallback onScanCameraTap;

  /// The on upload file tap.
  final VoidCallback onUploadFileTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_scanner_outlined),
            title: Text(l10n.inventoryActionManualAdd),
            onTap: onManualAddTap,
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.inventoryActionScanCamera),
            subtitle: isCameraEnabled
                ? null
                : Text(l10n.inventoryActionCameraUnsupported),
            enabled: isCameraEnabled,
            onTap: isCameraEnabled ? onScanCameraTap : null,
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: Text(l10n.inventoryActionUploadFile),
            onTap: onUploadFileTap,
          ),
        ],
      ),
    );
  }
}
