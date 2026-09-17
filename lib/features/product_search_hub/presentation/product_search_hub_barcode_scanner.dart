import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/barcode_scanner/app_barcode_scanner_page.dart';
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
        child: AppBarcodeScannerPage(
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
