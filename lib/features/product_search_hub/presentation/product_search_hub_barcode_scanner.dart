import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page/inventory_barcode_scanner_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens hub barcode scanner and returns the scanned barcode string.
Future<String?> openProductSearchHubBarcodeScanner({
  required BuildContext context,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: 1,
        child: InventoryBarcodeScannerPage(
          title: l10n.inventoryManualAddScanBarcodeAction,
          onBarcodeScanned: (scannedBarcode) async {
            sheetContext.pop(scannedBarcode);
            return true;
          },
        ),
      );
    },
  );
}
