import 'package:meta/meta.dart';

/// What saving a picked food shares with other users: a product in the
/// shared catalog and a barcode candidate for their scans (#789).
///
/// This is the one place that decides it; the writers only carry out the
/// answer. Shared serving suggestions follow `InventoryItem.staysPrivate`
/// alone.
@immutable
final class FoodSharing {
  const new _({
    required this.catalogProduct,
    required this.barcodeCandidate,
    required this.catalogIdAtOnce,
  });

  /// A picked food that becomes a new Vorrat item.
  ///
  /// A food that [staysPrivate], such as an AI estimate, shares nothing
  /// (#655, #701), and neither does a product outside the catalog that does
  /// not ask for it (#698). A picked catalog product points the item at its
  /// catalog id at once; a new one only once the catalog has it (#806).
  factory forNewItem({
    required bool staysPrivate,
    required bool requiresGlobalPersistence,
    required bool picksCatalogProduct,
  }) {
    if (staysPrivate) {
      return _private;
    }
    return FoodSharing._(
      catalogProduct: requiresGlobalPersistence,
      barcodeCandidate: picksCatalogProduct || requiresGlobalPersistence,
      catalogIdAtOnce: picksCatalogProduct,
    );
  }

  /// A picked food that replaces the product of a Vorrat item.
  ///
  /// A food that [staysPrivate] shares nothing, and the item keeps its
  /// pending id (#701). Without a picked catalog product a new one is
  /// written even when it does not ask for it, unlike
  /// [FoodSharing.forNewItem] (#698). That is kept as it was and not checked
  /// (#789). The item points at a new catalog product only once the catalog
  /// has it.
  factory forSwap({
    required bool staysPrivate,
    required bool requiresGlobalPersistence,
    required bool picksCatalogProduct,
  }) {
    if (staysPrivate) {
      return _private;
    }
    final catalogProduct = requiresGlobalPersistence || !picksCatalogProduct;
    return FoodSharing._(
      catalogProduct: catalogProduct,
      barcodeCandidate: true,
      catalogIdAtOnce: !catalogProduct,
    );
  }

  static const _private = FoodSharing._(
    catalogProduct: false,
    barcodeCandidate: false,
    catalogIdAtOnce: false,
  );

  /// Whether the product is written to the shared catalog.
  final bool catalogProduct;

  /// Whether the product's barcode is recorded for other users' scans,
  /// after the catalog write when there is one.
  final bool barcodeCandidate;

  /// Whether the item points at the catalog id at once. Otherwise it keeps
  /// its pending id until the catalog has a new [catalogProduct], or for
  /// good.
  final bool catalogIdAtOnce;

  /// Whether anything reaches other users.
  bool get sharesAnything => catalogProduct || barcodeCandidate;
}
