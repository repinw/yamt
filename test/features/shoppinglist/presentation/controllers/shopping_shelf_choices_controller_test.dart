import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/data/shopping_shelf_choice_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_shelf_choices_controller.dart';

import '../../../../helpers/fake_shopping_shelf_choice_repository.dart';

Future<ProviderContainer> _container(
  FakeShoppingShelfChoiceRepository shelves,
) async {
  addTearDown(shelves.dispose);
  final container = ProviderContainer(
    overrides: [
      shoppingShelfChoiceRepositoryProvider.overrideWithValue(shelves),
    ],
  );
  addTearDown(container.dispose);
  container.listen(shoppingShelfChoicesControllerProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  test('a failed read is an error, and a choice does not hide it with a '
      'partial map', () async {
    final shelves = FakeShoppingShelfChoiceRepository()
      ..watchError = StateError('denied');
    final container = await _container(shelves);
    expect(
      container.read(shoppingShelfChoicesControllerProvider),
      isA<AsyncError<ShoppingShelfChoices>>(),
    );

    final saved = await container
        .read(shoppingShelfChoicesControllerProvider.notifier)
        .choose('Milch', ShoppingShelf.frozen);

    expect(saved, isTrue);
    expect(shelves.choices, {'milch': ShoppingShelf.frozen});
    expect(
      container.read(shoppingShelfChoicesControllerProvider),
      isA<AsyncError<ShoppingShelfChoices>>(),
    );
  });
}
