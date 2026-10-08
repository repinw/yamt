import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
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
    final inCatalog =
        !requiresGlobalPersistence || await _saveProduct(resolvedProduct);
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
        globalFoodItem: resolvedProduct,
        selectedAt: _clock(),
      );
    }
    return (result: true, written: next);
  }

  Future<bool> _saveProduct(GlobalFoodItem product) async {
    try {
      return await _globalFoods.appendAll(<GlobalFoodItem>[product]);
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
}
