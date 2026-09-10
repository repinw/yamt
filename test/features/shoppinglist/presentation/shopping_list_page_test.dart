import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_page_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_stats_card.dart';
import 'package:yamt/l10n/app_localizations.dart';
import '../support/fake_shopping_list_repository.dart';

@Dependencies([shoppingSuggestions, shoppingSuggestionRetry])
Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ShoppingListPage(),
    ),
  );
}

ProviderContainer _createContainer(
  FakeShoppingListRepository repository, {
  List<ShoppingSuggestion> suggestions = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(repository),
      shoppingSuggestionSourceProvider.overrideWith(
        (ref) => AsyncData(suggestions),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(repository.dispose);
  return container;
}

String _statValue(WidgetTester tester, Key key) {
  final text = tester.widget<Text>(find.byKey(key));
  return text.data ?? '';
}

Future<void> _addItem(
  ProviderContainer container, {
  required String name,
  String? brand,
  int quantity = 1,
}) async {
  final controller = container.read(shoppingListControllerProvider.notifier);
  await controller.addItem(name: name, brand: brand, quantity: quantity);
}

@Dependencies([shoppingSuggestions, shoppingSuggestionRetry])
void main() {
  testWidgets('adds a purchase suggestion once and hides it', (
    tester,
  ) async {
    final repository = FakeShoppingListRepository();
    final container = _createContainer(
      repository,
      suggestions: const [
        ShoppingSuggestion(name: 'Milk', brand: 'Farm', purchaseCount: 2),
      ],
    );
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    expect(find.textContaining('Purchased 2 times'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Add item',
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.savedItems.single.name, 'Milk');
    expect(repository.savedItems.single.brand, 'Farm');
    expect(repository.savedItems.single.quantity, 1);
    expect(find.textContaining('Purchased 2 times'), findsNothing);
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('failed suggestion save restores suggestion and shows error', (
    tester,
  ) async {
    final repository = FakeShoppingListRepository()
      ..saveAllShouldFail = true
      ..saveDelay = const Duration(milliseconds: 500);
    final container = _createContainer(
      repository,
      suggestions: const [
        ShoppingSuggestion(name: 'Milk', brand: 'Farm', purchaseCount: 2),
      ],
    );
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Add item',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('Purchased 2 times'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      container.read(shoppingListControllerProvider).requireValue,
      isEmpty,
    );
  });

  testWidgets('fits narrow screens with large text in light and dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = _createContainer(FakeShoppingListRepository());
    await container.read(shoppingListControllerProvider.future);
    await _addItem(
      container,
      name: 'Whole grain bread with sunflower seeds',
      quantity: 2,
    );
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const ShoppingListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('shows empty state initially', (tester) async {
    final container = _createContainer(FakeShoppingListRepository());

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Shopping')),
      findsOneWidget,
    );
    expect(find.text('Your shopping list is empty.'), findsOneWidget);
  });

  testWidgets('does not render inline add form', (tester) async {
    final container = _createContainer(FakeShoppingListRepository());

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('updates stats values when list changes', (tester) async {
    final container = _createContainer(FakeShoppingListRepository());

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await _addItem(container, name: 'Bread');
    await tester.pumpAndSettle();

    expect(_statValue(tester, ShoppingListStatsCardKeys.entriesValue), '1');
    expect(_statValue(tester, ShoppingListStatsCardKeys.quantityValue), '1');

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();

    expect(_statValue(tester, ShoppingListStatsCardKeys.entriesValue), '1');
    expect(_statValue(tester, ShoppingListStatsCardKeys.quantityValue), '2');

    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(_statValue(tester, ShoppingListStatsCardKeys.entriesValue), '0');
    expect(_statValue(tester, ShoppingListStatsCardKeys.quantityValue), '0');
  });

  testWidgets('supports swipe-to-delete and quantity stepper', (tester) async {
    final container = _createContainer(FakeShoppingListRepository());

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await _addItem(container, name: 'Bread');
    await tester.pumpAndSettle();

    expect(find.textContaining('Qty: 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Qty: 2'), findsOneWidget);

    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Bread'), findsNothing);
  });

  testWidgets('decrement to zero keeps row crossed off', (tester) async {
    final container = _createContainer(FakeShoppingListRepository());

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await _addItem(container, name: 'Bread');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pumpAndSettle();

    expect(find.text('Bread'), findsOneWidget);
    expect(find.textContaining('Qty: 0'), findsOneWidget);
    expect(
      find.byKey(ShoppingListPageKeys.clearCrossedOffButton),
      findsOneWidget,
    );

    final title = tester.widget<Text>(find.text('Bread'));
    expect(title.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('clear crossed-off button removes crossed-off rows', (
    tester,
  ) async {
    final container = _createContainer(FakeShoppingListRepository());

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await _addItem(container, name: 'Bread');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ShoppingListPageKeys.clearCrossedOffButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ShoppingListPageKeys.clearCrossedOffConfirmButton),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bread'), findsNothing);
    expect(find.text('Your shopping list is empty.'), findsOneWidget);
  });

  testWidgets('cancel clear crossed-off keeps crossed-off rows', (
    tester,
  ) async {
    final container = _createContainer(FakeShoppingListRepository());

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await _addItem(container, name: 'Bread');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ShoppingListPageKeys.clearCrossedOffButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ShoppingListPageKeys.clearCrossedOffCancelButton),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.textContaining('Qty: 0'), findsOneWidget);
  });
}
