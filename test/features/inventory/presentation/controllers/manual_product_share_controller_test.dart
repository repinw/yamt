import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'manual_product_share_controller.dart';

import '../../../../helpers/inventory_item_whole_list_writes.dart';
import '../../../product_search_hub/support/fake_product_search_sources.dart';

void main() {
  final now = DateTime(2026, 10, 20);
  final product = GlobalFoodItem.create(
    id: 'off-4006381333931-muesli',
    name: 'Muesli',
    barcode: '4006381333931',
    now: now,
  );
  final pendingItem = InventoryItem.create(
    id: 'item-1',
    globalFoodItemId: buildPendingGlobalFoodItemId(
      product.resolvedFoodFingerprint,
    ),
    name: 'Muesli',
    entryDate: now,
    storeName: 'Manual',
    quantity: 1,
  );

  Future<(_MemoryInventory, _RecordingBarcodeCandidates)> share({
    required bool catalogWriteSucceeds,
    bool forVorrat = true,
  }) async {
    final inventory = _MemoryInventory([pendingItem]);
    final barcodes = _RecordingBarcodeCandidates();
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(inventory),
        globalFoodItemRepositoryProvider.overrideWithValue(
          catalogWriteSucceeds
              ? FakeGlobalFoodItemRepository()
              : _FailingCatalog(),
        ),
        globalBarcodeCandidateRepositoryProvider.overrideWithValue(barcodes),
      ],
    );
    addTearDown(container.dispose);
    // Like the save flow: the Vorrat controller stays for the link.
    final subscription = container.listen(
      inventoryItemsControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(inventoryItemsControllerProvider.future);

    await container
        .read(manualProductShareControllerProvider.notifier)
        .share(
          product: product,
          append: true,
          barcode: '4006381333931',
          selectedAt: now,
          pendingItem: forVorrat ? pendingItem : null,
        );
    return (inventory, barcodes);
  }

  test('points the item at the product once the catalog has it', () async {
    final (inventory, barcodes) = await share(catalogWriteSucceeds: true);

    expect(inventory.items.single.globalFoodItemId, product.id);
    expect(barcodes.recorded, ['4006381333931']);
  });

  test('shares the product of a plan without a Vorrat write', () async {
    final (inventory, barcodes) = await share(
      catalogWriteSucceeds: true,
      forVorrat: false,
    );

    expect(inventory.writes, 0);
    expect(barcodes.recorded, ['4006381333931']);
  });

  test('keeps the item private when the catalog write fails (#806)', () async {
    final (inventory, barcodes) = await share(catalogWriteSucceeds: false);

    expect(inventory.items.single, pendingItem);
    expect(inventory.writes, 0);
    expect(barcodes.recorded, isEmpty);
  });
}

class _FailingCatalog extends FakeGlobalFoodItemRepository {
  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async => false;
}

class _RecordingBarcodeCandidates implements GlobalBarcodeCandidateRepository {
  final recorded = <String>[];

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async => const <GlobalBarcodeCandidate>[];

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {
    recorded.add(barcode);
  }
}

class _MemoryInventory with InventoryItemWholeListWrites {
  new(this.items);

  List<InventoryItem> items;
  int writes = 0;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield items;
  }

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> replaceItems(List<InventoryItem> next) async {
    writes++;
    items = next;
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> next) async {
    items = [...items, ...next];
    return true;
  }
}
