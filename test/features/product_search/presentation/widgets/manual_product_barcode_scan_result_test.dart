import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_barcode_scan_result.dart';

void main() {
  test('selected result stores candidate, barcode, and scanner action', () {
    final candidate = InventoryBarcodeLookupCandidate.fromOffProduct(
      const OffProductSearchResult(
        code: '4006381333931',
        name: 'Muesli',
        score: 1,
      ),
    );

    final result = ManualBarcodeScanResult.selected(
      candidate: candidate,
      scannedBarcode: '4006381333931',
      action: InventoryBarcodeCandidateAction.eatNow,
    );

    expect(result.kind, ManualBarcodeScanResultKind.selected);
    expect(result.candidate, same(candidate));
    expect(result.scannedBarcode, '4006381333931');
    expect(result.action, InventoryBarcodeCandidateAction.eatNow);
  });

  test('not found result stores barcode without candidate or action', () {
    const result = ManualBarcodeScanResult.notFound(
      scannedBarcode: '4006381333931',
    );

    expect(result.kind, ManualBarcodeScanResultKind.notFound);
    expect(result.scannedBarcode, '4006381333931');
    expect(result.candidate, isNull);
    expect(result.action, isNull);
  });

  test('manual result stores barcode without candidate or action', () {
    const result = ManualBarcodeScanResult.manual(
      scannedBarcode: '4006381333931',
    );

    expect(result.kind, ManualBarcodeScanResultKind.manual);
    expect(result.scannedBarcode, '4006381333931');
    expect(result.candidate, isNull);
    expect(result.action, isNull);
  });

  test('scanner actions map to manual product actions', () {
    expect(
      manualProductActionFromBarcodeAction(
        InventoryBarcodeCandidateAction.eatNow,
      ),
      InventoryReceiptManualProductAction.eatNow,
    );
    expect(
      manualProductActionFromBarcodeAction(
        InventoryBarcodeCandidateAction.addToInventory,
      ),
      InventoryReceiptManualProductAction.addToInventory,
    );
    expect(
      manualProductActionFromBarcodeAction(null),
      InventoryReceiptManualProductAction.addToInventory,
    );
  });
}
