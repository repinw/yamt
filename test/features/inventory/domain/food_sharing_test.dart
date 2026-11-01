import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_sharing.dart';

typedef _Row = ({
  bool staysPrivate,
  bool requiresGlobalPersistence,
  bool picksCatalogProduct,
  bool catalogProduct,
  bool barcodeCandidate,
  bool catalogIdAtOnce,
});

const _newItemRows = <_Row>[
  // A private food shares nothing, whatever the search reported (#701).
  (
    staysPrivate: true,
    requiresGlobalPersistence: true,
    picksCatalogProduct: true,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  (
    staysPrivate: true,
    requiresGlobalPersistence: false,
    picksCatalogProduct: false,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  // A product outside the catalog that does not ask for it (#698).
  (
    staysPrivate: false,
    requiresGlobalPersistence: false,
    picksCatalogProduct: false,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  // A new catalog product links once the catalog has it (#806).
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: false,
    catalogProduct: true,
    barcodeCandidate: true,
    catalogIdAtOnce: false,
  ),
  // A picked catalog product only records its barcode.
  (
    staysPrivate: false,
    requiresGlobalPersistence: false,
    picksCatalogProduct: true,
    catalogProduct: false,
    barcodeCandidate: true,
    catalogIdAtOnce: true,
  ),
  // A picked catalog product with an edit patches it.
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: true,
    catalogProduct: true,
    barcodeCandidate: true,
    catalogIdAtOnce: true,
  ),
];

const _swapRows = <_Row>[
  (
    staysPrivate: true,
    requiresGlobalPersistence: true,
    picksCatalogProduct: false,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  // Unlike a new item, a swap without a picked catalog product writes one.
  (
    staysPrivate: false,
    requiresGlobalPersistence: false,
    picksCatalogProduct: false,
    catalogProduct: true,
    barcodeCandidate: true,
    catalogIdAtOnce: false,
  ),
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: false,
    catalogProduct: true,
    barcodeCandidate: true,
    catalogIdAtOnce: false,
  ),
  (
    staysPrivate: false,
    requiresGlobalPersistence: false,
    picksCatalogProduct: true,
    catalogProduct: false,
    barcodeCandidate: true,
    catalogIdAtOnce: true,
  ),
  // The item points at the product once the catalog write succeeded.
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: true,
    catalogProduct: true,
    barcodeCandidate: true,
    catalogIdAtOnce: false,
  ),
];

void main() {
  void expectRow(FoodSharing sharing, _Row row) {
    expect(sharing.catalogProduct, row.catalogProduct, reason: '$row');
    expect(sharing.barcodeCandidate, row.barcodeCandidate, reason: '$row');
    expect(sharing.catalogIdAtOnce, row.catalogIdAtOnce, reason: '$row');
  }

  test('a new item shares as the table says', () {
    for (final row in _newItemRows) {
      expectRow(
        FoodSharing.forNewItem(
          staysPrivate: row.staysPrivate,
          requiresGlobalPersistence: row.requiresGlobalPersistence,
          picksCatalogProduct: row.picksCatalogProduct,
        ),
        row,
      );
    }
  });

  test('a swap shares as the table says', () {
    for (final row in _swapRows) {
      expectRow(
        FoodSharing.forSwap(
          staysPrivate: row.staysPrivate,
          requiresGlobalPersistence: row.requiresGlobalPersistence,
          picksCatalogProduct: row.picksCatalogProduct,
        ),
        row,
      );
    }
  });
}
