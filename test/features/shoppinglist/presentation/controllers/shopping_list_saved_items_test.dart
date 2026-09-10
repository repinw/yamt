import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import '../../support/fake_shopping_list_repository.dart';

void main() {
  late FakeShoppingListRepository repository;
  late ProviderContainer container;
  late ShoppingListController controller;
  setUp(() async {
    repository = FakeShoppingListRepository();
    container = ProviderContainer(
      overrides: [shoppingListRepositoryProvider.overrideWithValue(repository)],
    )..listen(shoppingListControllerProvider, (_, _) {});
    controller = container.read(shoppingListControllerProvider.notifier);
    await container.read(shoppingListControllerProvider.future);
    await controller.addItem(name: 'Milk');
  });
  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });
  ShoppingListItem current() =>
      container.read(shoppingListControllerProvider).requireValue.single;

  test('favorite survives clearing and can be re-added after reload', () async {
    await controller.toggleFavorite(current().id);
    await controller.decrementQuantity(current().id);
    await controller.clearCrossedOffItems();
    expect(current().isArchived, isTrue);
    await controller.refresh();
    controller = container.read(shoppingListControllerProvider.notifier);
    expect(current().isFavorite, isTrue);
    await controller.addSavedItem(current().id);
    await controller.addSavedItem(current().id);
    expect(current().quantity, 1);
    expect(current().isArchived, isFalse);
  });

  Future<void> seedOverdueSavedItem() async {
    repository.emitWatchItems([
      current().copyWith(
        quantity: 0,
        isArchived: true,
        repeatEveryDays: 7,
        repeatQuantity: 3,
        nextDueDate: DateTime(2020),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);
  }

  test('schedule re-adds once and can be stopped', () async {
    await seedOverdueSavedItem();
    final id = current().id;
    await controller.processDue();
    await controller.processDue();
    expect(current().quantity, 3);
    await controller.setSchedule(id, days: 0, quantity: 1);
    expect(current().nextDueDate, isNull);
    expect(current().repeatEveryDays, 0);
  });

  test(
    'failed renewal preserves due date and retries without duplicates',
    () async {
      await seedOverdueSavedItem();
      repository.saveAllShouldFail = true;
      expect(await controller.processDue(), isFalse);
      expect(current().isArchived, isTrue);
      expect(current().nextDueDate, DateTime(2020));
      repository.saveAllShouldFail = false;
      expect(await controller.processDue(), isTrue);
      expect(current().quantity, 3);
    },
  );

  test(
    'setting an overdue schedule activates and advances in one save',
    () async {
      final id = current().id;
      await controller.toggleFavorite(id);
      await controller.removeItem(id);
      repository
        ..enqueueSaveResult(result: true)
        ..enqueueSaveResult(result: false);
      expect(
        await controller.setSchedule(
          id,
          days: 7,
          quantity: 3,
          firstDue: DateTime(2020),
        ),
        isTrue,
      );
      expect(current().isArchived, isFalse);
      expect(current().quantity, 3);
      expect(current().nextDueDate!.isAfter(DateTime.now()), isTrue);
      expect(repository.savedItems.single.quantity, 3);
      expect(await controller.processDue(), isTrue);
      // The queued failure remains: configuration used a single write.
      expect(await controller.incrementQuantity(id), isFalse);
      expect(current().quantity, 3);
    },
  );

  test(
    'failed schedule configuration rolls back settings and activation',
    () async {
      final id = current().id;
      await controller.toggleFavorite(id);
      await controller.removeItem(id);
      repository.saveAllShouldFail = true;
      expect(
        await controller.setSchedule(
          id,
          days: 7,
          quantity: 3,
          firstDue: DateTime(2020),
        ),
        isFalse,
      );
      expect(current().isArchived, isTrue);
      expect(current().quantity, 0);
      expect(current().repeatEveryDays, 0);
      expect(current().nextDueDate, isNull);
      repository.saveAllShouldFail = false;
      expect(
        await controller.setSchedule(
          id,
          days: 7,
          quantity: 3,
          firstDue: DateTime(2020),
        ),
        isTrue,
      );
      expect(current().quantity, 3);
      expect(current().isArchived, isFalse);
    },
  );

  test(
    'favorite save failure rolls back and invalid schedules are rejected',
    () async {
      repository.saveAllShouldFail = true;
      expect(await controller.toggleFavorite(current().id), isFalse);
      expect(current().isFavorite, isFalse);
      expect(
        await controller.setSchedule(current().id, days: -1, quantity: 1),
        isFalse,
      );
      expect(
        await controller.setSchedule(current().id, days: 7, quantity: 0),
        isFalse,
      );
    },
  );
}
