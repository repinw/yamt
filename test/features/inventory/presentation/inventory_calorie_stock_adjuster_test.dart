import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_stock_adjustment.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_calorie_stock_adjuster.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  new({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    _items = <InventoryItem>[..._items, ...items];
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    _items = List<InventoryItem>.from(items);
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.multi((controller) {
      controller.add(List<InventoryItem>.from(_items));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  Future<void> dispose() => _controller.close();
}

InventoryItem _milk({int currentAmount = 750}) {
  return InventoryItem.create(
    id: 'inventory-1',
    name: 'Milk',
    entryDate: DateTime(2026, 4, 2, 10),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.milliliter,
  );
}

InventoryItem _eggs() {
  return InventoryItem.create(
    id: 'inventory-1',
    name: 'Eggs',
    entryDate: DateTime(2026, 4, 2, 10),
    storeName: 'Store',
    quantity: 9,
    initialQuantity: 10,
    amountUnit: InventoryAmountUnit.piece,
  );
}

class _AdjusterHarness {
  const new({required this.container});

  final ProviderContainer container;

  Future<void> load() =>
      container.read(inventoryItemsControllerProvider.future);

  Future<CalorieInventoryStockAdjustment> adjust({
    required int reservedAmount,
    required double consumedAmount,
    String itemId = 'inventory-1',
  }) {
    return container.read(inventoryCalorieStockAdjusterProvider)(
      itemId: itemId,
      reservedAmount: reservedAmount,
      consumedAmount: consumedAmount,
    );
  }

  int? get currentAmount {
    return container
        .read(inventoryItemsControllerProvider)
        .asData
        ?.value
        .single
        .currentAmount;
  }

  int? get quantity {
    return container
        .read(inventoryItemsControllerProvider)
        .asData
        ?.value
        .single
        .quantity;
  }
}

_AdjusterHarness _buildHarness(List<InventoryItem> items) {
  final repository = _FakeInventoryItemRepository(initialItems: items);
  addTearDown(repository.dispose);

  final container = ProviderContainer(
    overrides: [inventoryItemRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  final subscription = container.listen(
    inventoryItemsControllerProvider,
    (_, _) {},
  );
  addTearDown(subscription.close);

  return _AdjusterHarness(container: container);
}

void main() {
  test('a larger amount takes the difference from the stock', () async {
    final harness = _buildHarness(<InventoryItem>[_milk()]);
    await harness.load();

    final adjustment = await harness.adjust(
      reservedAmount: 250,
      consumedAmount: 300,
    );

    expect(adjustment.status, CalorieInventoryStockAdjustmentStatus.applied);
    expect(adjustment.reservedAmount, 300);
    expect(harness.currentAmount, 700);
  });

  test('a smaller amount returns the difference to the stock', () async {
    final harness = _buildHarness(<InventoryItem>[_milk()]);
    await harness.load();

    final adjustment = await harness.adjust(
      reservedAmount: 250,
      consumedAmount: 100,
    );

    expect(adjustment.status, CalorieInventoryStockAdjustmentStatus.applied);
    expect(adjustment.reservedAmount, 100);
    expect(harness.currentAmount, 900);
  });

  test('an increase beyond the stock empties it and reports that', () async {
    final harness = _buildHarness(<InventoryItem>[_milk(currentAmount: 50)]);
    await harness.load();

    final adjustment = await harness.adjust(
      reservedAmount: 250,
      consumedAmount: 400,
    );

    expect(
      adjustment.status,
      CalorieInventoryStockAdjustmentStatus.stockExhausted,
    );
    expect(adjustment.reservedAmount, 300);
    expect(harness.currentAmount, 0);
  });

  test('an item counted in pieces keeps its stock', () async {
    final harness = _buildHarness(<InventoryItem>[_eggs()]);
    await harness.load();

    final adjustment = await harness.adjust(
      reservedAmount: 1,
      consumedAmount: 80,
    );

    expect(
      adjustment.status,
      CalorieInventoryStockAdjustmentStatus.stockUnchanged,
    );
    expect(adjustment.reservedAmount, 1);
    expect(harness.quantity, 9);
  });

  test('a missing source item leaves the stock alone', () async {
    final harness = _buildHarness(<InventoryItem>[_milk()]);
    await harness.load();

    final adjustment = await harness.adjust(
      itemId: 'inventory-gone',
      reservedAmount: 250,
      consumedAmount: 300,
    );

    expect(
      adjustment.status,
      CalorieInventoryStockAdjustmentStatus.sourceMissing,
    );
    expect(adjustment.reservedAmount, 250);
    expect(harness.currentAmount, 750);
  });
}
