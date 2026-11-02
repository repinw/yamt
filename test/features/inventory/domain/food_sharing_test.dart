import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_sharing.dart';

typedef _Row = ({
  bool staysPrivate,
  bool requiresGlobalPersistence,
  bool picksCatalogProduct,
  bool picksExternalProduct,
  bool hasBarcode,
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
    picksExternalProduct: false,
    hasBarcode: true,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  (
    staysPrivate: true,
    requiresGlobalPersistence: false,
    picksCatalogProduct: false,
    picksExternalProduct: false,
    hasBarcode: true,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  // A product outside the catalog that does not ask for it (#698).
  (
    staysPrivate: false,
    requiresGlobalPersistence: false,
    picksCatalogProduct: false,
    picksExternalProduct: false,
    hasBarcode: true,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  // A typed product with a barcode becomes a catalog product, and the item
  // links once the catalog has it (#806).
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: false,
    picksExternalProduct: false,
    hasBarcode: true,
    catalogProduct: true,
    barcodeCandidate: true,
    catalogIdAtOnce: false,
  ),
  // A typed product without a barcode stays the user's own.
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: false,
    picksExternalProduct: false,
    hasBarcode: false,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  // A product from the external database is shared without a barcode too.
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: false,
    picksExternalProduct: true,
    hasBarcode: false,
    catalogProduct: true,
    barcodeCandidate: true,
    catalogIdAtOnce: false,
  ),
  // A picked catalog product only records its barcode.
  (
    staysPrivate: false,
    requiresGlobalPersistence: false,
    picksCatalogProduct: true,
    picksExternalProduct: false,
    hasBarcode: true,
    catalogProduct: false,
    barcodeCandidate: true,
    catalogIdAtOnce: true,
  ),
  // A picked catalog product with an edit patches it.
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: true,
    picksExternalProduct: false,
    hasBarcode: true,
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
    picksExternalProduct: false,
    hasBarcode: true,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  // Like a new item, an own recent food stays private.
  (
    staysPrivate: false,
    requiresGlobalPersistence: false,
    picksCatalogProduct: false,
    picksExternalProduct: false,
    hasBarcode: true,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: false,
    picksExternalProduct: false,
    hasBarcode: false,
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  ),
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: false,
    picksExternalProduct: true,
    hasBarcode: true,
    catalogProduct: true,
    barcodeCandidate: true,
    catalogIdAtOnce: false,
  ),
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: false,
    picksExternalProduct: false,
    hasBarcode: true,
    catalogProduct: true,
    barcodeCandidate: true,
    catalogIdAtOnce: false,
  ),
  (
    staysPrivate: false,
    requiresGlobalPersistence: false,
    picksCatalogProduct: true,
    picksExternalProduct: false,
    hasBarcode: true,
    catalogProduct: false,
    barcodeCandidate: true,
    catalogIdAtOnce: true,
  ),
  // The item points at the product once the catalog write succeeded.
  (
    staysPrivate: false,
    requiresGlobalPersistence: true,
    picksCatalogProduct: true,
    picksExternalProduct: false,
    hasBarcode: true,
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
          picksExternalProduct: row.picksExternalProduct,
          hasBarcode: row.hasBarcode,
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
          picksExternalProduct: row.picksExternalProduct,
          hasBarcode: row.hasBarcode,
        ),
        row,
      );
    }
  });
}
