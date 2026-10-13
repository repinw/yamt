import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/features/inventory/application/inventory_item_writer.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_stock_changes.dart';

part 'inventory_item_edit_service.g.dart';

/// The Vorrat item edit service provider.
@riverpod
InventoryItemEditService inventoryItemEditService(Ref ref) =>
    InventoryItemEditService(
      writer: ref.watch(inventoryItemWriterProvider),
      globalFoods: ref.watch(globalFoodItemRepositoryProvider),
      barcodeCandidates: ref.watch(globalBarcodeCandidateRepositoryProvider),
      clock: ref.watch(clockProvider),
    );

/// Edits full Vorrat items: their details and their product.
class InventoryItemEditService {
  /// Creates the service.
  new({
    required this._writer,
    required this._globalFoods,
    required this._barcodeCandidates,
    required this._clock,
  });

  final InventoryItemWriter _writer;
  final GlobalFoodItemRepository _globalFoods;
  final GlobalBarcodeCandidateRepository _barcodeCandidates;
  final DateTime Function() _clock;

  /// Saves an edit of a full item; its stock stays unless the edit changes
  /// how the stock is counted.
  Future<InventoryItemChange<bool>> update(
    List<InventoryItem> items,
    InventoryItem item,
  ) async {
    final index = items.indexWhere((current) => current.id == item.id);
    if (index < 0 || !items[index].isFullyAvailable) {
      return (result: false, written: null);
    }
    final next = List<InventoryItem>.from(items)
      ..[index] = buildInventoryItemEditSaveItem(
        currentItem: items[index],
        editedItem: item,
      );
    final saved = await _writer.save(items, next);
    return (result: saved, written: saved ? next : null);
  }

  /// Points a full item at another product.
  ///
  /// With [requiresGlobalPersistence], [resolvedProduct] is written to the
  /// shared catalog first. Without it, the product is in the catalog already,
  /// or it has a pending id, like an AI food (#655) or a product whose front
  /// photo shows no package (#658): such a product is the user's own, so
  /// neither the catalog nor the barcode candidates get it.
  Future<InventoryItemChange<bool>> swap(
    List<InventoryItem> items, {
    required String itemId,
    required GlobalFoodItem resolvedProduct,
    required bool requiresGlobalPersistence,
    String? weight,
  }) async {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index < 0 || !items[index].isFullyAvailable) {
      return (result: false, written: null);
    }
    final inCatalog = requiresGlobalPersistence
        ? await _saveProduct(resolvedProduct)
        : !isPendingGlobalFoodItemId(resolvedProduct.id);
    final next = List<InventoryItem>.from(items)
      ..[index] = buildSwappedItem(
        sourceItem: items[index],
        resolvedProduct: resolvedProduct,
        weight: weight,
        canReferenceGlobalItem: inCatalog,
      );
    if (!await _writer.save(items, next)) {
      return (result: false, written: null);
    }
    final barcode = resolvedProduct.normalizedBarcode;
    if (inCatalog && barcode != null && barcode.isNotEmpty) {
      await _barcodeCandidates.recordSelection(
        barcode: barcode,
        globalFoodItem: _shared(resolvedProduct),
        selectedAt: _clock(),
      );
    }
    return (result: true, written: next);
  }

  Future<bool> _saveProduct(GlobalFoodItem product) async {
    try {
      return await _globalFoods.appendAll(<GlobalFoodItem>[_shared(product)]);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist swapped product ${product.id}. '
        'Continuing with inventory-only save.',
        name: 'InventoryItemMutationService',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// [product] as other users see it in the catalog and the barcode
  /// candidates. Its image is left out when it is a private food photo, like
  /// the front photo of a product without a package (#658), or a photo that
  /// is still uploading (#414): the swapped item keeps it.
  static GlobalFoodItem _shared(GlobalFoodItem product) =>
      product.copyWith(imageUrl: shareableProductImageUrl(product.imageUrl));
}
