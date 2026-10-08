import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';

class _Household implements InventoryUserSession {
  @override
  String get householdId => 'household-1';
}

InventoryItem _milk({int quantity = 3}) => InventoryItem.create(
  id: 'milk',
  name: 'Milk',
  entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
  storeName: 'Store',
  quantity: quantity,
  initialQuantity: 3,
);

void main() {
  test(
    'an eat shows through the item stream of the local Firestore cache',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreInventoryItemRepository(
        session: _Household(),
        sessionShutdownSignal: SessionShutdownSignal(),
        store: FirestoreInventoryItemStore(
          firestore: firestore,
          cipher: PayloadCipher(await PayloadCipher.newDataKey()),
        ),
      );
      await repository.save(_milk());
      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final quantities = <int>[];
      container.listen(
        inventoryItemsControllerProvider,
        (_, next) => quantities.addAll([
          if (next.value case [final item]) item.quantity,
        ]),
      );
      await container.read(inventoryItemsControllerProvider.future);

      final eaten = await container
          .read(inventoryItemsControllerProvider.notifier)
          .eatItemDetailed('milk', 1);
      await pumpEventQueue();

      expect(eaten, isNotNull);
      expect(
        container.read(inventoryItemsControllerProvider).value?.single.quantity,
        2,
      );
      expect((await repository.readAll()).single.quantity, 2);
    },
  );
}
