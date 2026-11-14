import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_import_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_import_flow.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_import_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_shelf_labels.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

import '../support/fake_shopping_list_repository.dart';

const _answer = '''
{"items": [
  {"name": "Milch", "quantity": 1, "shelf": "chilled"},
  {"name": "Hackfleisch", "quantity": 1, "note": "500 g", "shelf": "meatFish"},
  {"name": "Qwrtz", "quantity": 2, "shelf": "other"}
 ],
 "skipped": ["Samstag"]}
''';

const _openKey = Key('open_import');

ShoppingListItem _milk() => const ShoppingListItem(
  id: 'milk',
  name: 'Milch',
  normalizedName: 'milch',
  normalizedBrand: '',
  quantity: 2,
  estimatedUnitPrice: 0,
);

Future<FakeShoppingListRepository> _open(
  WidgetTester tester,
  Future<String?> Function(Map<String, Object?> inputs) client,
) async {
  final list = FakeShoppingListRepository(initialItems: [_milk()]);
  final container = ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(list),
      shoppingListImportRepositoryProvider.overrideWithValue(
        ShoppingListImportRepository(templateClient: client),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(list.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: _openKey,
              onPressed: () => unawaited(showShoppingListImport(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  return list;
}

Future<void> _readText(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(ShoppingImportKeys.textField),
    'Samstag\nMilch\nHackfleisch 500 g\n2 Qwrtz',
  );
  await tester.pump();
  expect(
    tester.widget<Text>(find.byKey(ShoppingImportKeys.lineCount)).data,
    '4 lines pasted',
  );
  await tester.tap(find.byKey(ShoppingImportKeys.readButton));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

bool _checked(WidgetTester tester, int index) => tester
    .widget<Checkbox>(find.byKey(ShoppingImportKeys.rowCheckbox(index)))
    .value!;

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('shows what was read against the list', (tester) async {
    await _open(tester, (_) async => _answer);
    await _readText(tester);

    expect(_text(tester, ShoppingImportKeys.foundCount), '3 products found');

    expect(
      _text(tester, ShoppingImportKeys.rowDetail(0)),
      'Already on the list (2×)',
    );
    expect(find.byKey(ShoppingImportKeys.rowQuantity(0)), findsNothing);
    expect(_checked(tester, 0), isFalse);
    await tester.tap(find.byKey(ShoppingImportKeys.rowCheckbox(0)));
    await tester.pump();
    expect(_text(tester, ShoppingImportKeys.rowQuantity(0)), '+1 more');
    await tester.tap(find.byKey(ShoppingImportKeys.rowCheckbox(0)));
    await tester.pump();

    final mince =
        lookUpShoppingCatalog('Hackfleisch')?.shelf ?? ShoppingShelf.meatFish;
    expect(
      _text(tester, ShoppingImportKeys.rowDetail(1)),
      '${shoppingShelfLabel(l10n, mince)} · Note: 500 g',
    );
    expect(_text(tester, ShoppingImportKeys.rowQuantity(1)), '1×');
    expect(_checked(tester, 1), isTrue);

    expect(
      _text(tester, ShoppingImportKeys.rowDetail(2)),
      'Not in the catalog · goes under Other',
    );
    expect(_text(tester, ShoppingImportKeys.rowQuantity(2)), '2×');

    await tester.scrollUntilVisible(
      find.byKey(ShoppingImportKeys.skipped),
      100,
    );
    expect(find.text('1 line skipped:'), findsOneWidget);
    expect(find.text('Samstag'), findsOneWidget);
    expect(find.text('Add 2 products to the list'), findsOneWidget);
  });

  testWidgets('renames, unselects and adds the rest to the list', (
    tester,
  ) async {
    final list = await _open(tester, (_) async => _answer);
    await _readText(tester);

    await tester.tap(find.byKey(ShoppingImportKeys.rowName(2)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ShoppingImportKeys.renameField), 'Tofu');
    await tester.tap(find.byKey(ShoppingImportKeys.renameSave));
    await tester.pumpAndSettle();
    expect(find.text('Tofu'), findsOneWidget);

    await tester.tap(find.byKey(ShoppingImportKeys.rowCheckbox(1)));
    await tester.pump();
    expect(find.text('Add 1 product to the list'), findsOneWidget);

    await tester.tap(find.byKey(ShoppingImportKeys.addButton));
    await tester.pumpAndSettle();

    expect(find.byType(ShoppingImportPage), findsNothing);
    expect(list.savedItems.map((item) => item.name), ['Milch', 'Tofu']);
    expect(list.savedItems.first.quantity, 2);
    expect(list.savedItems.last.quantity, 2);
  });

  testWidgets('a failed save keeps the review open', (tester) async {
    final list = await _open(tester, (_) async => _answer);
    await _readText(tester);
    list.saveAllShouldFail = true;

    await tester.tap(find.byKey(ShoppingImportKeys.addButton));
    await tester.pumpAndSettle();

    expect(find.byType(ShoppingImportPage), findsOneWidget);
    expect(find.text(l10n.shoppingListSaveFailed), findsOneWidget);
    expect(find.byKey(ShoppingImportKeys.addButton), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    var calls = 0;
    await _open(tester, (_) async {
      calls++;
      if (calls == 1) throw TimeoutException('slow');
      return _answer;
    });
    await _readText(tester);

    expect(find.text('We could not read the list.'), findsOneWidget);
    await tester.tap(find.byKey(ShoppingImportKeys.retryButton));
    await tester.pumpAndSettle();

    expect(_text(tester, ShoppingImportKeys.foundCount), '3 products found');
  });

  testWidgets('an empty read says so and offers a retry', (tester) async {
    await _open(tester, (_) async => '{"items": [], "skipped": ["Hallo"]}');
    await _readText(tester);

    expect(find.text('We found no products.'), findsOneWidget);
    expect(find.byKey(ShoppingImportKeys.retryButton), findsOneWidget);
  });

  testWidgets('back from the review keeps the pasted text', (tester) async {
    await _open(tester, (_) async => _answer);
    await _readText(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Samstag\nMilch\nHackfleisch 500 g\n2 Qwrtz'),
      findsOneWidget,
    );
    expect(find.byKey(ShoppingImportKeys.readButton), findsOneWidget);
  });
}
