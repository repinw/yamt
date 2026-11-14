import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_import_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_shelf_choice_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_import_page.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_finish_page.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/fake_shopping_shelf_choice_repository.dart';
import '../../test/helpers/household_members_overrides.dart';
import '../../test/helpers/memory_app_preferences.dart';

const _answer = '''
{"items": [
  {"name": "Milch", "quantity": 1, "shelf": "chilled"},
  {"name": "Hackfleisch", "quantity": 1, "note": "500 g", "shelf": "meatFish"}
 ],
 "skipped": ["Samstag"]}
''';

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

  testWidgets('a pasted list goes on the list, the trip ends, and the '
      'private list keeps its own entries', (tester) async {
    final repository = FakeShoppingListRepository(
      initialItems: [
        const ShoppingListItem(
          id: 'milk',
          name: 'Milch',
          normalizedName: 'milch',
          normalizedBrand: '',
          quantity: 1,
          estimatedUnitPrice: 0,
        ),
      ],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        shoppingListRepositoryProvider.overrideWithValue(repository),
        shoppingShelfChoiceRepositoryProvider.overrideWithValue(
          FakeShoppingShelfChoiceRepository(),
        ),
        shoppingListImportRepositoryProvider.overrideWithValue(
          ShoppingListImportRepository(templateClient: (_) async => _answer),
        ),
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        // Someone else is in the household, so there is a private list.
        ...householdMembersOverrides(memberCount: 2),
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
          home: ShoppingListPage(),
        ),
      ),
    );
    await _waitFor(tester, find.byKey(ShoppingListPageKeys.tile('milk')));

    // Paste a list: Milch is on the list already, so only Hackfleisch is
    // picked.
    await _tap(tester, find.byKey(ShoppingListPageKeys.importButton));
    await _waitFor(tester, find.byType(ShoppingImportPage));
    await tester.enterText(
      find.byKey(ShoppingImportKeys.textField),
      'Samstag\nMilch\nHackfleisch 500 g',
    );
    await tester.pump();
    await _tap(tester, find.byKey(ShoppingImportKeys.readButton));
    await _waitFor(tester, find.byKey(ShoppingImportKeys.foundCount));
    await _tap(tester, find.byKey(ShoppingImportKeys.addButton));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ShoppingImportPage), findsNothing);
    expect(repository.savedItems.map((item) => item.name), [
      'Milch',
      'Hackfleisch',
    ]);
    expect(repository.savedItems.last.note, '500 g');

    // Put the minced meat in the cart and finish; the receipt comes later.
    final mince = repository.savedItems.last.id;
    await _tap(tester, find.byKey(ShoppingListPageKeys.tile(mince)));
    await _waitForProgress(tester, '1 of 2 in the cart');
    await _tap(tester, find.byKey(ShoppingListPageKeys.finishButton));
    await _waitFor(tester, find.byType(ShoppingListFinishPage));
    await _tap(tester, find.byKey(ShoppingListPageKeys.finishConfirmButton));
    await tester.pumpAndSettle();
    expect(find.byType(ShoppingListFinishPage), findsNothing);
    expect(repository.savedItems.map((item) => item.name), ['Milch']);

    // The private list starts empty; an entry added there stays private and
    // leaves the household list alone.
    await _tap(tester, find.byKey(ShoppingListPageKeys.scope('private')));
    await tester.pumpAndSettle();
    expect(find.byKey(ShoppingListPageKeys.tile('milk')), findsNothing);
    await _tap(tester, find.byKey(ShoppingListPageKeys.addButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ShoppingListPageKeys.addSheetField),
      'Deo',
    );
    await tester.pump();
    await _tap(tester, find.byKey(ShoppingListPageKeys.addSheetNewEntry));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(ShoppingListPageKeys.addSheetDoneButton));
    await tester.pumpAndSettle();
    expect(repository.savedItems.map((item) => (item.name, item.isPrivate)), [
      ('Milch', false),
      ('Deo', true),
    ]);
    expect(tester.takeException(), isNull);
  });
}
