import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_barcode_scan_result.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Barcode scanner mode options derived from hub route mode.
class ProductSearchHubBarcodeScannerOptions {
  /// Creates barcode scanner options.
  const ProductSearchHubBarcodeScannerOptions({
    required this.showActionButtons,
    required this.eatOnly,
  });

  /// Whether barcode candidates show explicit store/eat actions.
  final bool showActionButtons;

  /// Whether only eat actions are available.
  final bool eatOnly;
}

/// Resolves scanner options for the active hub route args.
ProductSearchHubBarcodeScannerOptions productSearchHubBarcodeOptionsForArgs(
  ProductSearchHubRouteArgs args,
) {
  return switch (args.mode) {
    ProductSearchHubMode.inventory =>
      const ProductSearchHubBarcodeScannerOptions(
        showActionButtons: false,
        eatOnly: false,
      ),
    ProductSearchHubMode.selection =>
      const ProductSearchHubBarcodeScannerOptions(
        showActionButtons: false,
        eatOnly: false,
      ),
    ProductSearchHubMode.diary => const ProductSearchHubBarcodeScannerOptions(
      showActionButtons: true,
      eatOnly: true,
    ),
  };
}

/// Opens hub barcode scanner and returns the scanner result.
Future<ManualBarcodeScanResult?> openProductSearchHubBarcodeScanner({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
}) {
  final l10n = AppLocalizations.of(context)!;
  final options = productSearchHubBarcodeOptionsForArgs(args);
  return showModalBottomSheet<ManualBarcodeScanResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: 1,
        child: InventoryBarcodeScannerPage(
          title: l10n.inventoryManualAddScanBarcodeAction,
          showActionButtons: options.showActionButtons,
          eatOnly: options.eatOnly,
          onProductSelected: (candidate, scannedBarcode, action) async {
            sheetContext.pop(
              ManualBarcodeScanResult.selected(
                candidate: candidate,
                scannedBarcode: scannedBarcode,
                action: action,
              ),
            );
            return true;
          },
          onProductNotFound: (scannedBarcode) async {
            sheetContext.pop(
              ManualBarcodeScanResult.notFound(scannedBarcode: scannedBarcode),
            );
            return true;
          },
          onCreateManualProduct: (scannedBarcode) async {
            sheetContext.pop(
              ManualBarcodeScanResult.manual(scannedBarcode: scannedBarcode),
            );
            return true;
          },
        ),
      );
    },
  );
}
