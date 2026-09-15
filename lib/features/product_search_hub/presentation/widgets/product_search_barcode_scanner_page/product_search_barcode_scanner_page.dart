import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_barcode_lookup_candidate.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_barcode_scanner_page/'
    'product_search_barcode_scanner_view.dart';

/// Defines inventory barcode scanner page with an app bar and scanner view.
@Dependencies([
  productSearchGateway,
])
class InventoryBarcodeScannerPage extends StatelessWidget {
  /// The inventory barcode scanner page.
  const InventoryBarcodeScannerPage({
    required this.title,
    super.key,
    this.onBarcodeScanned,
    this.onProductSelected,
    this.onProductNotFound,
    this.onCreateManualProduct,
    this.showActionButtons = true,
    this.eatOnly = false,
    this.actions,
  }) : assert(
         onBarcodeScanned != null || onProductSelected != null,
         'Either onBarcodeScanned or onProductSelected must be provided.',
       );

  /// The title shown in the app bar.
  final String title;

  /// Direct raw barcode scanned callback.
  final InventoryBarcodeScanCallback? onBarcodeScanned;

  /// The on product selected callback.
  final InventoryBarcodeProductSelectionCallback? onProductSelected;

  /// The on product not found callback.
  final InventoryBarcodeNotFoundCallback? onProductNotFound;

  /// The on create manual product callback.
  final InventoryBarcodeManualProductCallback? onCreateManualProduct;

  /// Whether candidate rows show explicit action buttons.
  final bool showActionButtons;

  /// Whether only eat actions should be shown.
  final bool eatOnly;

  /// Optional actions displayed in the app bar.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: InventoryBarcodeScannerView(
        onBarcodeScanned: onBarcodeScanned,
        onProductSelected: onProductSelected,
        onProductNotFound: onProductNotFound,
        onCreateManualProduct: onCreateManualProduct,
        showActionButtons: showActionButtons,
        eatOnly: eatOnly,
      ),
    );
  }
}
