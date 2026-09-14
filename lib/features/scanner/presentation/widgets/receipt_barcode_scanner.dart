import 'package:flutter/material.dart';
import 'package:yamt/core/widgets/barcode_scanner/app_barcode_scanner_page.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_support.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'receipt_barcode_input_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the barcode scanner for receipt review item matching.
///
/// Falls back to [ReceiptBarcodeInputDialog] if camera scanning is not
/// supported on current platform. In camera mode, an app bar action allows
/// entering the barcode manually via keyboard.
Future<String?> openReceiptBarcodeScanner(BuildContext context) async {
  if (!isMobileBarcodeScanSupported()) {
    return ReceiptBarcodeInputDialog.show(context);
  }

  final l10n = AppLocalizations.of(context);
  final title = l10n?.inventoryManualAddScanBarcodeAction ?? 'Barcode scannen';

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: 1,
        child: AppBarcodeScannerPage(
          title: title,
          actions: [
            IconButton(
              key: const Key('receipt_barcode_scanner_manual_action'),
              icon: const Icon(Icons.keyboard_outlined),
              tooltip:
                  l10n?.receiptReviewManualInputTooltip ?? 'Manuell eingeben',
              onPressed: () async {
                final manual = await ReceiptBarcodeInputDialog.show(
                  sheetContext,
                );
                if (manual != null &&
                    manual.isNotEmpty &&
                    sheetContext.mounted) {
                  Navigator.of(sheetContext).pop(manual);
                }
              },
            ),
          ],
          onBarcodeScanned: (scannedBarcode) async {
            Navigator.of(sheetContext).pop(scannedBarcode);
            return true;
          },
        ),
      );
    },
  );
}
