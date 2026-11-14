import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_suggestion_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/memory_app_preferences.dart';

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

/// Pumps until the progress label reads [expected], at most five seconds.
Future<void> _waitForProgress(WidgetTester tester, String expected) async {
  final label = find.byKey(ShoppingListPageKeys.progressLabel);
  String? text() =>
      label.evaluate().isEmpty ? null : tester.widget<Text>(label).data;
  for (var i = 0; i < 50 && text() != expected; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(text(), expected);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ticking off, the entry sheet, suggestions, adding and finishing a '
    'trip',
    (tester) async {
      final repository = FakeShoppingListRepository(
        initialItems: [
          _item('milk', 'Milk'),
          _item('bread', 'Bread'),
          _item('eggs', 'Eggs'),
        ],
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShoppingListPage(
              suggestions: AsyncData([
                ShoppingSuggestion(name: 'Oats', isLowStock: true),
                ShoppingSuggestion(name: 'Butter', purchaseCount: 3),
              ]),
            ),
          ),
        ),
      );
      await _waitFor(tester, _tile('milk'));
      await _waitForProgress(tester, '0 of 3 in the cart');

      // Tick two entries off; after the linger they sit in the cart.
      await _tap(tester, _tile('milk'));
      await _tap(tester, _tile('bread'));
      await tester.pump(AppShopping.tickLinger);
      await _waitFor(tester, _chip('milk'));
      await _waitFor(tester, _chip('bread'));
      expect(_tile('milk'), findsNothing);
      await _waitForProgress(tester, '2 of 3 in the cart');

      // Put one back.
      await _tap(tester, _chip('bread'));
      await _waitFor(tester, _tile('bread'));
      expect(_chip('bread'), findsNothing);
      await _waitForProgress(tester, '1 of 3 in the cart');

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

      // Push the first suggestion back, then take the one that moved up.
      final strip = find.byType(ShoppingSuggestionCard);
      expect(
        tester.widget<ShoppingSuggestionCard>(strip.first).suggestion.name,
        'Oats',
      );
      await _tap(
        tester,
        find.descendant(
          of: find.byKey(ShoppingListPageKeys.suggestion('oats|')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ShoppingSuggestionCard>(strip.first).suggestion.name,
        'Butter',
      );
      await _tap(
        tester,
        find.byKey(ShoppingListPageKeys.suggestion('butter|')),
      );
      await _waitForProgress(tester, '1 of 4 in the cart');

      // Add two entries in the sheet, one with a count, and take one back.
      await _tap(tester, find.byKey(ShoppingListPageKeys.addButton));
      await _waitFor(tester, find.byKey(ShoppingListPageKeys.addSheetField));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(ShoppingListPageKeys.addSheetField),
        '2 Apples',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(ShoppingListPageKeys.addSheetNewEntry));
      await _waitFor(tester, find.byKey(ShoppingListPageKeys.addSheetAdded(0)));
      await tester.enterText(
        find.byKey(ShoppingListPageKeys.addSheetField),
        'Salt',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(ShoppingListPageKeys.addSheetNewEntry));
      await _waitFor(tester, find.byKey(ShoppingListPageKeys.addSheetAdded(1)));
      await _tap(tester, find.byKey(ShoppingListPageKeys.addSheetAdded(1)));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(ShoppingListPageKeys.addSheetDoneButton));
      await tester.pumpAndSettle();
      await _waitForProgress(tester, '1 of 5 in the cart');

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
      // Tiles are built as they scroll into view.
      final list = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final id in ['bread', 'eggs']) {
        await tester.scrollUntilVisible(_tile(id), 200, scrollable: list);
        expect(_tile(id), findsOneWidget);
      }
      expect(repository.savedItems.map((item) => item.name), [
        'Bread',
        'Eggs',
        'Butter',
        'Apples',
      ]);
      expect(
        repository.savedItems
            .singleWhere((item) => item.name == 'Apples')
            .quantity,
        2,
      );
      expect(
        repository.savedItems.singleWhere((item) => item.id == 'eggs').quantity,
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
