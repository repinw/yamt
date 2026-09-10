import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/l10n/app_localizations.dart';
import '../support/fake_shopping_list_repository.dart';

@Dependencies([shoppingSuggestions, shoppingSuggestionRetry])
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShoppingListPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _menu(WidgetTester tester, String action) async {
  await tester.tap(find.byTooltip('Item settings').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

@Dependencies([shoppingSuggestions, shoppingSuggestionRetry])
void main() {
  testWidgets('favorite can be set from menu, removed from list and re-added', (
    tester,
  ) async {
    final container = await _pump(tester);
    await _menu(tester, 'Save as favorite');
    expect(
      container
          .read(shoppingListControllerProvider)
          .requireValue
          .single
          .isFavorite,
      isTrue,
    );
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Favorites & recurring items'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    await tester.tap(find.byTooltip('Add item'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(shoppingListControllerProvider)
          .requireValue
          .single
          .quantity,
      1,
    );
  });

  testWidgets('schedule dialog validates input, saves and stops a recurrence', (
    tester,
  ) async {
    final container = await _pump(tester);
    await _menu(tester, 'Recurring item');
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number from 1 to 365.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '14');
    await tester.enterText(find.byType(TextFormField).last, '3');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final item = container
        .read(shoppingListControllerProvider)
        .requireValue
        .single;
    expect(item.repeatEveryDays, 14);
    expect(item.repeatQuantity, 3);
    expect(find.textContaining('3 items every 14 days'), findsOneWidget);
    await _menu(tester, 'Recurring item');
    await tester.tap(find.text('Stop repeating'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(shoppingListControllerProvider)
          .requireValue
          .single
          .repeatEveryDays,
      0,
    );
  });

  testWidgets('canceling schedule leaves saved settings unchanged', (
    tester,
  ) async {
    final container = await _pump(tester);
    await _menu(tester, 'Recurring item');
    await tester.enterText(find.byType(TextFormField).first, '30');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(shoppingListControllerProvider)
          .requireValue
          .single
          .repeatEveryDays,
      0,
    );
  });
}
