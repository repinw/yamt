import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/inventory_item_discard_service.dart';
import 'package:yamt/features/inventory/application/inventory_item_mutation_service.dart';
import 'package:yamt/features/inventory/application/inventory_item_writer.dart';
import 'package:yamt/features/inventory/data/inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

import '../../../helpers/inventory_item_whole_list_writes.dart';

final _now = DateTime.utc(2026, 10, 8, 12);

InventoryItem _milk({int quantity = 3}) => InventoryItem.create(
  id: 'milk',
  name: 'Milk',
  entryDate: _now,
  storeName: 'Store',
  quantity: quantity,
  initialQuantity: 3,
  unitPrice: 1,
);

class _Repository extends Fake with InventoryItemWholeListWrites {
  new(this.items);

  List<InventoryItem> items;

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> replaceItems(List<InventoryItem> next) async {
    items = next;
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> added) =>
      replaceItems([...items, ...added]);
}

class _Activity extends Fake implements InventoryActivityEventRepository {
  final events = <InventoryActivityEvent>[];

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> added) async {
    events.addAll(added);
    return true;
  }
}

class _Discards extends Fake implements InventoryDiscardEventRepository {
  new({required this.saves});

  final bool saves;

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async => saves;
}

void main() {
  late _Repository repository;
  late _Activity activity;

  InventoryItemWriter writer() {
    var id = 0;
    return InventoryItemWriter(
      inventory: repository,
      activity: activity,
      actor: const InventoryActivityActor(userId: 'u', displayName: null),
      newId: () => 'id-${id++}',
    );
  }

  InventoryItemMutationService service() =>
      InventoryItemMutationService(writer: writer(), clock: () => _now);

  InventoryItemDiscardService discards({required bool saves}) =>
      InventoryItemDiscardService(
        writer: writer(),
        discardEvents: _Discards(saves: saves),
        clock: () => _now,
      );

  setUp(() {
    repository = _Repository([_milk()]);
    activity = _Activity();
  });

  test('eat caps at the stock, writes, and records the change', () async {
    final change = await service().eat(repository.items, 'milk', 5);

    expect(change.result?.removedAmount, 3);
    expect(repository.items.single.quantity, 0);
    expect(change.written?.single.quantity, 0);
    expect(
      activity.events.single.type,
      InventoryActivityEventType.itemConsumed,
    );
  });

  test(
    'a throw-away whose discard cannot be saved gives the stock back',
    () async {
      final change = await discards(
        saves: false,
      ).throwAway(repository.items, 'milk', 2, InventoryDiscardReason.expired);

      expect(change.result, isNull);
      expect(change.written, isNull);
      expect(repository.items.single.quantity, 3);
      expect(activity.events, isEmpty);
    },
  );

  test('a deleted item comes back at its place', () async {
    repository.items = [_milk(), _milk().copyWith(id: 'oat')];
    final mutations = service();

    final deleted = await mutations.delete(repository.items, 'milk');
    expect(repository.items.map((item) => item.id), ['oat']);

    final restored = await mutations.restoreDeleted(
      deleted.written!,
      deleted.result!,
    );
    expect(restored.result, isTrue);
    expect(restored.written?.map((item) => item.id), ['milk', 'oat']);
  });
}
