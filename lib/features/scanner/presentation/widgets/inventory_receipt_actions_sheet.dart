import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Modal bottom sheet displaying available inventory receipt and product add
/// actions.
class InventoryReceiptActionsSheet extends StatelessWidget {
  /// Creates an [InventoryReceiptActionsSheet].
  const new({
    required this.isCameraEnabled,
    required this.onManualAddTap,
    required this.onScanCameraTap,
    required this.onUploadFileTap,
    super.key,
  });

  /// Whether camera scanning is supported on current platform.
  final bool isCameraEnabled;

  /// Callback when manual product search is tapped.
  final VoidCallback onManualAddTap;

  /// Callback when camera scan is tapped.
  final VoidCallback onScanCameraTap;

  /// Callback when file upload is tapped.
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
