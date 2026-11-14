import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_shelf_choice_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_shopping_shelf_choice_repository.dart';
import '../../../helpers/household_members_overrides.dart';
import '../../../helpers/memory_app_preferences.dart';
import '../support/fake_shopping_list_repository.dart';

ShoppingListItem _item(String id, {bool isPrivate = false}) => ShoppingListItem(
  id: id,
  name: id,
  normalizedName: id.toLowerCase(),
  normalizedBrand: '',
  quantity: 1,
  estimatedUnitPrice: 0,
  isPrivate: isPrivate,
);

Future<FakeShoppingListRepository> _pump(
  WidgetTester tester, {
  MemoryAppPreferences? preferences,
  bool isShared = true,
}) async {
  final repository = FakeShoppingListRepository(
    initialItems: [
      _item('Milk'),
      _item('Bread'),
      _item('Deo', isPrivate: true),
    ],
  );
  final shelves = FakeShoppingShelfChoiceRepository();
  // The shelves stop after the container, which still listens to them.
  addTearDown(shelves.dispose);
  final container = ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(repository),
      shoppingShelfChoiceRepositoryProvider.overrideWithValue(shelves),
      ...householdMembersOverrides(memberCount: isShared ? 2 : 1),
      appPreferencesProvider.overrideWithValue(
        preferences ?? MemoryAppPreferences(),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(repository.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShoppingListPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Finder _tile(String id) => find.byKey(ShoppingListPageKeys.tile(id));
Finder _lock(String id) => find.descendant(
  of: _tile(id),
  matching: find.byIcon(Icons.lock_outline_rounded),
);

Future<void> _show(WidgetTester tester, String scope) async {
  await tester.tap(find.byKey(ShoppingListPageKeys.scope(scope)));
  await tester.pumpAndSettle();
}

Future<void> _addTyped(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ShoppingListPageKeys.addButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(ShoppingListPageKeys.addSheetField), name);
  await tester.pump();
  await tester.tap(find.byKey(ShoppingListPageKeys.addSheetNewEntry));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ShoppingListPageKeys.addSheetDoneButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('alone in the household there is one list: no choice, every '
      'entry, no lock', (tester) async {
    await _pump(tester, isShared: false);

    expect(find.byKey(ShoppingListPageKeys.scopeBar), findsNothing);
    expect(_tile('Milk'), findsOneWidget);
    expect(_tile('Deo'), findsOneWidget);
    expect(_lock('Deo'), findsNothing);
  });

  testWidgets('the household list shows first, with the counts of each '
      'list', (tester) async {
    await _pump(tester);

    expect(find.text('Household · 2'), findsOneWidget);
    expect(find.text('Private · 1'), findsOneWidget);
    expect(find.text('Both · 3'), findsOneWidget);
    expect(find.text('Shared with everyone in your household.'), findsOne);
    expect(_tile('Milk'), findsOneWidget);
    expect(_tile('Deo'), findsNothing);
    expect(find.text('Add to household'), findsOneWidget);
  });

  testWidgets('the private list shows only private entries, without a '
      'lock', (tester) async {
    await _pump(tester);

    await _show(tester, 'private');

    expect(_tile('Deo'), findsOneWidget);
    expect(_tile('Milk'), findsNothing);
    expect(_lock('Deo'), findsNothing);
    expect(find.text('Only you see this list.'), findsOneWidget);
    expect(find.text('Add privately'), findsOneWidget);
  });

  testWidgets('both lists mark the private entries with a lock', (
    tester,
  ) async {
    await _pump(tester);

    await _show(tester, 'both');

    expect(_tile('Milk'), findsOneWidget);
    expect(_lock('Deo'), findsOneWidget);
    expect(_lock('Milk'), findsNothing);
  });

  testWidgets('an entry added on the private list is private, and in both '
      'lists it goes to the household', (tester) async {
    final repository = await _pump(tester);

    await _show(tester, 'private');
    await _addTyped(tester, 'Gift');
    await _show(tester, 'both');
    await _addTyped(tester, 'Eggs');

    final saved = {
      for (final item in repository.savedItems) item.name: item.isPrivate,
    };
    expect(saved['Gift'], isTrue);
    expect(saved['Eggs'], isFalse);
  });

  testWidgets('finishing takes only the cart of the list shown', (
    tester,
  ) async {
    final repository = await _pump(tester);
    await _show(tester, 'both');
    for (final id in ['Milk', 'Deo']) {
      await tester.tap(_tile(id));
      await tester.pump();
      await tester.pump(AppShopping.tickLinger);
      await tester.pumpAndSettle();
    }

    await _show(tester, 'household');
    await tester.tap(find.byKey(ShoppingListPageKeys.finishButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ShoppingListPageKeys.finishConfirmButton));
    await tester.pumpAndSettle();

    expect(repository.savedItems.map((item) => item.name), ['Bread', 'Deo']);
  });

  testWidgets('the list shown is kept for the next visit', (tester) async {
    final preferences = MemoryAppPreferences();
    await _pump(tester, preferences: preferences);
    await _show(tester, 'private');

    await tester.pumpWidget(const SizedBox());
    await _pump(tester, preferences: preferences);

    expect(_tile('Deo'), findsOneWidget);
    expect(_tile('Milk'), findsNothing);
  });

  testWidgets('a private list that failed shows a retry there, not on the '
      'household list', (tester) async {
    final repository = await _pump(tester)
      ..privateUnreadable = true
      ..emitWatchItems([_item('Milk'), _item('Bread')]);
    await tester.pumpAndSettle();
    final retry = find.byKey(ShoppingListPageKeys.privateRetryButton);
    expect(retry, findsNothing);

    await _show(tester, 'private');
    expect(retry, findsOneWidget);

    repository.privateUnreadable = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(retry, findsNothing);
  });
}
