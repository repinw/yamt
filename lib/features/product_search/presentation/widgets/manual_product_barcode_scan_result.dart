import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/product_search/presentation/controllers/manual_product_search_models.dart';

/// Outcome kind from the manual product barcode scanner sheet.
enum ManualBarcodeScanResultKind {
  /// The user selected a matching product candidate.
  selected,

  /// No product was found for the scanned barcode.
  notFound,

  /// User chose to create their own product for the scanned barcode.
  manual,
}

/// Selected or missing barcode result from the scanner sheet.
class ManualBarcodeScanResult {
  const ManualBarcodeScanResult._({
    required this.kind,
    this.action,
    this.candidate,
    this.scannedBarcode,
  });

  /// A barcode candidate was selected.
  const ManualBarcodeScanResult.selected({
    required InventoryBarcodeLookupCandidate candidate,
    required String scannedBarcode,
    required InventoryBarcodeCandidateAction action,
  }) : this._(
         kind: ManualBarcodeScanResultKind.selected,
         action: action,
         candidate: candidate,
         scannedBarcode: scannedBarcode,
       );

  /// The scanned barcode was not found.
  const ManualBarcodeScanResult.notFound({required String scannedBarcode})
    : this._(
        kind: ManualBarcodeScanResultKind.notFound,
        scannedBarcode: scannedBarcode,
      );

  /// The user wants to create their own product.
  const ManualBarcodeScanResult.manual({required String scannedBarcode})
    : this._(
        kind: ManualBarcodeScanResultKind.manual,
        scannedBarcode: scannedBarcode,
      );

  /// Result kind.
  final ManualBarcodeScanResultKind kind;

  /// Candidate action from scanner buttons.
  final InventoryBarcodeCandidateAction? action;

  /// Selected lookup candidate.
  final InventoryBarcodeLookupCandidate? candidate;

  /// Scanned barcode text.
  final String? scannedBarcode;
}

/// Converts scanner action buttons into manual product save actions.
InventoryReceiptManualProductAction manualProductActionFromBarcodeAction(
  InventoryBarcodeCandidateAction? action,
) {
  return action == InventoryBarcodeCandidateAction.eatNow
      ? InventoryReceiptManualProductAction.eatNow
      : InventoryReceiptManualProductAction.addToInventory;
}
