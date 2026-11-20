import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_import_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_shelf_choice_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_review.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_scope.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_import_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_scope_controller.dart';

import '../../../../helpers/fake_shopping_shelf_choice_repository.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../support/fake_shopping_list_repository.dart';

const _answer = '''
{"items": [
  {"name": "Milch", "quantity": 1, "shelf": "chilled"},
  {"name": "Qwrtz", "quantity": 2, "note": "500 g", "shelf": "other"}
 ],
 "skipped": ["Samstag"]}
''';

ShoppingListItem _milk({bool isPrivate = false}) => ShoppingListItem(
  id: 'milk',
  name: 'Milch',
  normalizedName: 'milch',
  normalizedBrand: '',
  quantity: 2,
  estimatedUnitPrice: 0,
  isPrivate: isPrivate,
);

class _Setup {
  new(this.container, this.list, this.states, this.shelves);

  final ProviderContainer container;
  final FakeShoppingListRepository list;
  final List<AsyncValue<ShoppingImportReview>?> states;
  final FakeShoppingShelfChoiceRepository shelves;

  ShoppingImportController get controller =>
      container.read(shoppingImportControllerProvider.notifier);

  ShoppingImportReview get review =>
      container.read(shoppingImportControllerProvider)!.requireValue;
}

Future<_Setup> _setUp(
  Future<String?> Function(Map<String, Object?> inputs) client, {
  ShoppingListItem? listed,
}) async {
  final list = FakeShoppingListRepository(initialItems: [listed ?? _milk()]);
  final shelves = FakeShoppingShelfChoiceRepository();
  addTearDown(shelves.dispose);
  final container = ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(list),
      appUpdateStatusProvider.overrideWith((ref) => const Stream.empty()),
      shoppingShelfChoiceRepositoryProvider.overrideWithValue(shelves),
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      shoppingListImportRepositoryProvider.overrideWithValue(
        ShoppingListImportRepository(templateClient: client),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(list.dispose);
  final states = <AsyncValue<ShoppingImportReview>?>[];
  final subscription = container.listen(
    shoppingImportControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );
  addTearDown(subscription.close);
  await container.read(shoppingListControllerProvider.future);
  return _Setup(container, list, states, shelves);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('in both lists, a private entry does not count as listed', () async {
    final setup = await _setUp(
      (_) async => _answer,
      listed: _milk(isPrivate: true),
    );
    await setup.container
        .read(shoppingListScopeControllerProvider.notifier)
        .select(ShoppingListScope.both);

    await setup.controller.readText('Milch');

    final milk = setup.review.rows.first;
    expect((milk.listedQuantity, milk.isSelected), (null, true));
  });

  test('reads pasted text into a review against the list', () async {
    final sent = <Map<String, Object?>>[];
    final setup = await _setUp((inputs) async {
      sent.add(inputs);
      return _answer;
    });

    await setup.controller.readText('Milch\n2 Qwrtz');

    expect(sent, [
      {'text': 'Milch\n2 Qwrtz'},
    ]);
    expect(setup.states.first, isNull);
    expect(setup.states[1], isA<AsyncLoading<ShoppingImportReview>>());
    final review = setup.review;
    expect(review.rows.first.listedQuantity, 2);
    expect(review.rows.first.isSelected, isFalse);
    expect(review.selectedLines.map((line) => line.name), ['Qwrtz']);
    expect(review.skipped, ['Samstag']);
  });

  test('a failed read is an error that retry reads again', () async {
    var calls = 0;
    final setup = await _setUp((_) async {
      calls++;
      if (calls == 1) throw TimeoutException('slow');
      return _answer;
    });

    await setup.controller.readText('Milch');
    expect(
      setup.container.read(shoppingImportControllerProvider),
      isA<AsyncError<ShoppingImportReview>>(),
    );

    await setup.controller.retry();
    expect(calls, 2);
    expect(setup.review.rows, hasLength(2));
  });

  test('toggle, rename and restart change the review', () async {
    final setup = await _setUp((_) async => _answer);
    await setup.controller.readText('Milch');

    setup.controller.toggle(0);
    expect(setup.review.rows.first.isSelected, isTrue);

    setup.controller.rename(1, 'Brot');
    expect(setup.review.rows[1].line.name, 'Brot');
    setup.controller.rename(1, '  ');
    expect(setup.review.rows[1].line.name, 'Brot');

    setup.controller.restart();
    expect(setup.container.read(shoppingImportControllerProvider), isNull);
  });

  test('addSelected puts the selected products on the list', () async {
    final setup = await _setUp((_) async => _answer);
    await setup.controller.readText('Milch');

    expect(await setup.controller.addSelected(), isTrue);

    final saved = setup.list.savedItems;
    expect(saved, hasLength(2));
    expect(saved.firstWhere((item) => item.id == 'milk').quantity, 2);
    final added = saved.firstWhere((item) => item.name == 'Qwrtz');
    expect(added.quantity, 2);
    expect(added.note, '500 g');
  });

  test('addSelected reports a failed save', () async {
    final setup = await _setUp((_) async => _answer);
    await setup.controller.readText('Milch');
    setup.list.saveAllShouldFail = true;

    expect(await setup.controller.addSelected(), isFalse);
  });

  test('a read the user went back from is dropped', () async {
    final answer = Completer<String?>();
    final setup = await _setUp((_) => answer.future);

    final read = setup.controller.readText('Milch');
    setup.controller.restart();
    answer.complete(_answer);
    await read;

    expect(setup.container.read(shoppingImportControllerProvider), isNull);
  });

  test(
    'addSelected remembers the guessed shelf of an unknown product',
    () async {
      const answer =
          '{"items": [{"name": "Qwrtz", "quantity": 1, "shelf": "drinks"}],'
          ' "skipped": []}';
      final setup = await _setUp((_) async => answer);
      await setup.controller.readText('Qwrtz');

      expect(await setup.controller.addSelected(), isTrue);

      expect(setup.shelves.choices, {'qwrtz': ShoppingShelf.drinks});
    },
  );

  test('a guessed shelf leaves the shelf the household chose', () async {
    const answer =
        '{"items": [{"name": "Qwrtz", "quantity": 1, "shelf": "pantry"}],'
        ' "skipped": []}';
    final setup = await _setUp((_) async => answer);
    setup.shelves.choices = {'qwrtz': ShoppingShelf.drinks};
    await setup.controller.readText('Qwrtz');

    expect(await setup.controller.addSelected(), isTrue);

    expect(setup.shelves.choices, {'qwrtz': ShoppingShelf.drinks});
  });
}
