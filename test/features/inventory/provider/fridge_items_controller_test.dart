import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';

class _FakeFridgeItemRepository implements FridgeItemRepository {
  _FakeFridgeItemRepository({required this.onReadAll});

  final Future<List<FridgeItem>> Function() onReadAll;

  @override
  Future<List<FridgeItem>> readAll() {
    return onReadAll();
  }

  @override
  Future<bool> saveAll(List<FridgeItem> items) async {
    return true;
  }

  @override
  Future<bool> appendAll(List<FridgeItem> items) async {
    return true;
  }
}

FridgeItem _item(String id) {
  return FridgeItem(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.0,
  );
}

void main() {
  test('build loads fridge items from repository', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a')],
    );
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final items = await container.read(fridgeItemsControllerProvider.future);

    expect(items, hasLength(1));
    expect(items.single.id, 'a');
  });

  test('refresh reloads updated repository state', () async {
    var phase = 0;
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async {
        if (phase == 0) {
          return <FridgeItem>[_item('a')];
        }
        return <FridgeItem>[_item('a'), _item('b')];
      },
    );
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(fridgeItemsControllerProvider.future);
    phase = 1;
    await container.read(fridgeItemsControllerProvider.notifier).refresh();

    final refreshed = container.read(fridgeItemsControllerProvider).value;
    expect(refreshed, isNotNull);
    expect(refreshed, hasLength(2));
  });
}
