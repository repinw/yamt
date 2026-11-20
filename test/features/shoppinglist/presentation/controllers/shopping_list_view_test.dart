import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/household/application/household_members_provider.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_shelf_choice_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_scope.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_order_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_scope_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_ticks_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_view.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_suggestion_views.dart';

import '../../../../helpers/fake_shopping_shelf_choice_repository.dart';
import '../../../../helpers/household_members_overrides.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../support/fake_shopping_list_repository.dart';

ShoppingListItem _item(
  String name, {
  bool isDone = false,
  bool isPrivate = false,
  bool isArchived = false,
}) => ShoppingListItem(
  id: name,
  name: name,
  normalizedName: name.toLowerCase(),
  normalizedBrand: '',
  quantity: isArchived ? 0 : 1,
  estimatedUnitPrice: 0,
  isDone: isDone,
  isPrivate: isPrivate,
  isArchived: isArchived,
  isFavorite: isArchived,
);

Future<ProviderContainer> _container(
  List<ShoppingListItem> items, {
  int memberCount = 2,
}) async {
  final list = FakeShoppingListRepository(initialItems: items);
  final shelves = FakeShoppingShelfChoiceRepository();
  addTearDown(list.dispose);
  addTearDown(shelves.dispose);
  final container = ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(list),
      appUpdateStatusProvider.overrideWith((ref) => const Stream.empty()),
      shoppingShelfChoiceRepositoryProvider.overrideWithValue(shelves),
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      ...householdMembersOverrides(memberCount: memberCount),
    ],
  );
  addTearDown(container.dispose);
  container.listen(shoppingListViewProvider, (_, _) {});
  await container.read(shoppingListControllerProvider.future);
  container.listen(householdMembersProvider, (_, _) {});
  // The members arrive from a stream after the profile; wait for them.
  for (var tries = 0; tries < 50; tries++) {
    if (container.read(householdMembersProvider).value?.length == memberCount) {
      break;
    }
    await Future<void>.delayed(Duration.zero);
  }
  return container;
}

ShoppingListView _view(ProviderContainer container) =>
    container.read(shoppingListViewProvider).requireValue;

List<String> _tileNames(ShoppingListView view) => [
  for (final group in view.sections.tileGroups)
    for (final tile in group.tiles) tile.item.name,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('alone in the household both lists show as one', () async {
    final container = await _container([
      _item('Milch'),
      _item('Deo', isPrivate: true),
    ], memberCount: 1);

    expect(_view(container).scope, ShoppingListScope.both);
  });

  test('shows the household list, with counts of every list', () async {
    final container = await _container([
      _item('Milch'),
      _item('Brot', isDone: true),
      _item('Deo', isPrivate: true),
      _item('Salz', isArchived: true),
    ]);

    final view = _view(container);
    expect(_tileNames(view), ['Milch']);
    expect(view.sections.cart.map((item) => item.name), ['Brot']);
    expect(view.trip.cart.map((item) => item.name), ['Brot']);
    expect(view.trip.openCount, 1);
    expect(view.scopeCounts, {
      ShoppingListScope.household: 2,
      ShoppingListScope.private: 1,
      ShoppingListScope.both: 3,
    });
  });

  test('both lists and the name order put every tile in one group', () async {
    final container = await _container([
      _item('Milch'),
      _item('Deo', isPrivate: true),
    ]);
    await container
        .read(shoppingListScopeControllerProvider.notifier)
        .select(ShoppingListScope.both);
    await container.read(shoppingListOrderControllerProvider.notifier).toggle();

    final view = _view(container);
    expect(view.sections.tileGroups.single.shelf, isNull);
    expect(_tileNames(view), ['Deo', 'Milch']);
  });

  test('a tap shows at once and lingers as a ticked tile', () async {
    final container = await _container([_item('Milch')]);
    final milk = _view(container).sections.tileGroups.single.tiles.single;

    final saving = container
        .read(shoppingListTicksControllerProvider.notifier)
        .toggle(milk.item, save: ({required done}) async => true);

    final view = _view(container);
    expect(view.sections.doneCount, 1);
    expect(_tileNames(view), ['Milch']);
    await saving;
  });

  test('the add sheet matches only the list it adds to', () async {
    final container = await _container([
      _item('Milch'),
      _item('Deo', isPrivate: true),
    ]);
    container.listen(shoppingAddTargetItemsProvider, (_, _) {});
    List<String> names() => [
      for (final item in container.read(shoppingAddTargetItemsProvider))
        item.name,
    ];

    expect(names(), ['Milch']);
    await container
        .read(shoppingListScopeControllerProvider.notifier)
        .select(ShoppingListScope.both);
    expect(names(), ['Milch']);
    await container
        .read(shoppingListScopeControllerProvider.notifier)
        .select(ShoppingListScope.private);
    expect(names(), ['Deo']);
  });

  test('a private favorite is offered only when adding to the private '
      'list', () async {
    final container = await _container([
      _item('Deo', isPrivate: true, isArchived: true),
    ]);
    List<String> favorites() {
      final provider = shoppingAddOfferForProvider(
        text: '',
        languageCode: 'de',
        suggestions: ShoppingSuggestionList(const <ShoppingSuggestion>[]),
      );
      container.listen(provider, (_, _) {});
      return [
        for (final placed in container.read(provider).hits) placed.hit.name,
      ];
    }

    expect(favorites(), isEmpty);
    await container
        .read(shoppingListScopeControllerProvider.notifier)
        .select(ShoppingListScope.private);
    expect(favorites(), ['Deo']);
  });
}
