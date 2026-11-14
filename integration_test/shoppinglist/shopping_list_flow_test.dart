import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';

ShoppingListItem _item(String id, String name) => ShoppingListItem(
  id: id,
  name: name,
  normalizedName: name.toLowerCase(),
  normalizedBrand: '',
  quantity: 1,
  estimatedUnitPrice: 0,
);

Finder _tile(String id) => find.byKey(ShoppingListPageKeys.tile(id));
Finder _chip(String id) => find.byKey(ShoppingListPageKeys.cartChip(id));

String _sheetQuantity(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ShoppingListPageKeys.sheetQuantity)).data!;

/// Pumps until [finder] matches, at most five seconds.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ticking off, putting back, the sheet and finishing a trip', (
    tester,
  ) async {
    final repository = FakeShoppingListRepository(
      initialItems: [
        _item('milk', 'Milk'),
        _item('bread', 'Bread'),
        _item('eggs', 'Eggs'),
      ],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [shoppingListRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
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
    await _waitFor(tester, _tile('milk'));
    expect(find.text('0 of 3 in the cart'), findsOneWidget);

    // Tick two entries off; after the linger they sit in the cart.
    await _tap(tester, _tile('milk'));
    await _tap(tester, _tile('bread'));
    await tester.pump(AppShopping.tickLinger);
    await _waitFor(tester, _chip('milk'));
    await _waitFor(tester, _chip('bread'));
    expect(_tile('milk'), findsNothing);
    expect(find.text('2 of 3 in the cart'), findsOneWidget);

    // Put one back.
    await _tap(tester, _chip('bread'));
    await _waitFor(tester, _tile('bread'));
    expect(_chip('bread'), findsNothing);
    expect(find.text('1 of 3 in the cart'), findsOneWidget);

    // Raise the quantity of an open entry in the sheet.
    await tester.longPress(_tile('eggs'));
    await _waitFor(tester, find.byKey(ShoppingListPageKeys.sheetQuantity));
    await tester.pumpAndSettle();
    await _tap(tester, find.byTooltip('Increase quantity'));
    for (var i = 0; i < 50 && _sheetQuantity(tester) != '2'; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(_sheetQuantity(tester), '2');
    await tester.tapAt(const Offset(5, 5));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _waitFor(
      tester,
      find.byKey(ShoppingListPageKeys.tileQuantity('eggs')),
    );

    // Finish the trip: only the entry in the cart leaves the list.
    await _tap(tester, find.byKey(ShoppingListPageKeys.finishButton));
    await _waitFor(
      tester,
      find.byKey(ShoppingListPageKeys.finishConfirmButton),
    );
    await _tap(tester, find.byKey(ShoppingListPageKeys.finishConfirmButton));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(_chip('milk'), findsNothing);
    expect(_tile('bread'), findsOneWidget);
    expect(_tile('eggs'), findsOneWidget);
    expect(repository.savedItems.map((item) => item.id), ['bread', 'eggs']);
    expect(
      repository.savedItems.singleWhere((item) => item.id == 'eggs').quantity,
      2,
    );
    expect(tester.takeException(), isNull);
  });
}
