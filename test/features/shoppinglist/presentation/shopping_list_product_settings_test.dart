import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_shopping_list_repository.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  final repository = FakeShoppingListRepository();
  final container = ProviderContainer(
    overrides: [shoppingListRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  addTearDown(repository.dispose);
  await container.read(shoppingListControllerProvider.future);
  await container
      .read(shoppingListControllerProvider.notifier)
      .addItem(name: 'Milk');
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
  return container;
}

Future<void> _openSheet(WidgetTester tester, String id) async {
  await tester.longPress(find.byKey(ShoppingListPageKeys.tile(id)));
  await tester.pumpAndSettle();
}

ShoppingListItem _milk(ProviderContainer container) =>
    container.read(shoppingListControllerProvider).requireValue.single;

void main() {
  testWidgets(
    'favorite can be set in the sheet, removed from list and re-added',
    (tester) async {
      final container = await _pump(tester);
      await _openSheet(tester, _milk(container).id);
      await tester.tap(find.byKey(ShoppingListPageKeys.sheetFavorite));
      await tester.pumpAndSettle();
      expect(_milk(container).isFavorite, isTrue);

      await tester.tap(find.byKey(ShoppingListPageKeys.sheetRemoveButton));
      await tester.pumpAndSettle();
      expect(find.text('Favorites & recurring items'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(_milk(container).isArchived, isTrue);

      await tester.tap(find.byTooltip('Add item'));
      await tester.pumpAndSettle();
      expect(_milk(container).quantity, 1);
      expect(_milk(container).isArchived, isFalse);
    },
  );

  testWidgets('the menu of a saved product drops the favorite', (tester) async {
    final container = await _pump(tester);
    await _openSheet(tester, _milk(container).id);
    await tester.tap(find.byKey(ShoppingListPageKeys.sheetFavorite));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Item settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove favorite'));
    await tester.pumpAndSettle();

    expect(_milk(container).isFavorite, isFalse);
  });

  testWidgets('schedule dialog validates input, saves and stops a recurrence', (
    tester,
  ) async {
    final container = await _pump(tester);
    await _openSheet(tester, _milk(container).id);
    await tester.tap(find.byKey(ShoppingListPageKeys.sheetSchedule));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number from 1 to 365.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '14');
    await tester.enterText(find.byType(TextFormField).last, '3');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final item = _milk(container);
    expect(item.repeatEveryDays, 14);
    expect(item.repeatQuantity, 3);
    expect(find.textContaining('3 items every 14 days'), findsWidgets);
    await tester.tap(find.byKey(ShoppingListPageKeys.sheetSchedule));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop repeating'));
    await tester.pumpAndSettle();
    expect(_milk(container).repeatEveryDays, 0);
  });

  testWidgets('canceling schedule leaves saved settings unchanged', (
    tester,
  ) async {
    final container = await _pump(tester);
    await _openSheet(tester, _milk(container).id);
    await tester.tap(find.byKey(ShoppingListPageKeys.sheetSchedule));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '30');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_milk(container).repeatEveryDays, 0);
  });
}
