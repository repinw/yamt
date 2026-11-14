import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_page_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_suggestions.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_suggestion_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../support/fake_shopping_list_repository.dart';

ShoppingListItem _item(
  String id, {
  String? name,
  int quantity = 1,
  bool isDone = false,
  bool isFavorite = false,
}) => ShoppingListItem(
  id: id,
  name: name ?? id,
  normalizedName: (name ?? id).toLowerCase(),
  normalizedBrand: '',
  quantity: quantity,
  estimatedUnitPrice: 0,
  isDone: isDone,
  isFavorite: isFavorite,
);

Widget _app(ProviderContainer container, {Widget? suggestionStrip}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ShoppingListPage(suggestionStrip: suggestionStrip),
    ),
  );
}

ProviderContainer _container(
  FakeShoppingListRepository repository, {
  MemoryAppPreferences? preferences,
}) {
  final container = ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(repository),
      appPreferencesProvider.overrideWithValue(
        preferences ?? MemoryAppPreferences(),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(repository.dispose);
  return container;
}

Future<FakeShoppingListRepository> _pump(
  WidgetTester tester,
  List<ShoppingListItem> items,
) async {
  final repository = FakeShoppingListRepository(initialItems: items);
  await tester.pumpWidget(_app(_container(repository)));
  await tester.pumpAndSettle();
  return repository;
}

Finder _tile(String id) => find.byKey(ShoppingListPageKeys.tile(id));
Finder _suggestion(String key) =>
    find.byKey(ShoppingListPageKeys.suggestion(key));
Finder _chip(String id) => find.byKey(ShoppingListPageKeys.cartChip(id));

String _progress(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ShoppingListPageKeys.progressLabel)).data!;

String _sheetQuantity(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ShoppingListPageKeys.sheetQuantity)).data!;

ShoppingListItem _saved(FakeShoppingListRepository repository, String id) =>
    repository.savedItems.singleWhere((item) => item.id == id);

Future<void> _tick(WidgetTester tester, String id) async {
  await tester.tap(_tile(id));
  await tester.pump();
  await tester.pump(AppShopping.tickLinger);
  await tester.pump();
}

Future<void> _openSheet(WidgetTester tester, String id) async {
  await tester.longPress(_tile(id));
  await tester.pumpAndSettle();
}

Future<void> _setView(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpScaled(
  WidgetTester tester,
  List<ShoppingListItem> items, {
  required double scale,
}) async {
  await _setView(tester, const Size(360, 800));
  final container = _container(FakeShoppingListRepository(initialItems: items));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const ShoppingListPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('states', () {
    testWidgets('shows a loading view until the list arrives', (tester) async {
      final gate = Completer<List<ShoppingListItem>>();
      final repository = FakeShoppingListRepository(
        onReadAll: () => gate.future,
      );
      await tester.pumpWidget(_app(_container(repository)));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete([_item('milk')]);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_tile('milk'), findsOneWidget);
    });

    testWidgets('shows an error and retry loads the list again', (
      tester,
    ) async {
      var calls = 0;
      final repository = FakeShoppingListRepository(
        onReadAll: () async {
          calls++;
          if (calls == 1) throw StateError('offline');
          return [_item('milk')];
        },
      );
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repository.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();

      expect(find.text('Could not load shopping list items.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load shopping list items.'), findsNothing);
      expect(_tile('milk'), findsOneWidget);
    });

    testWidgets('shows the empty state without progress or tiles', (
      tester,
    ) async {
      await _pump(tester, const []);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Shopping'),
        ),
        findsOneWidget,
      );
      expect(find.text('Your shopping list is empty.'), findsOneWidget);
      expect(find.byKey(ShoppingListPageKeys.progressLabel), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('add', () {
    testWidgets('the add button opens the dialog and adds the entry', (
      tester,
    ) async {
      final repository = await _pump(tester, const []);

      await tester.tap(find.byKey(ShoppingListPageKeys.addButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Bread');
      await tester.tap(find.widgetWithText(FilledButton, 'Add item').last);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.savedItems.single.name, 'Bread');
      expect(find.text('Bread'), findsOneWidget);
      expect(_progress(tester), '0 of 1 in the cart');
    });

    testWidgets('adds a purchase suggestion once and hides it', (tester) async {
      final repository = FakeShoppingListRepository();
      await tester.pumpWidget(
        _app(
          _container(repository),
          suggestionStrip: const ShoppingListSuggestions(
            key: ValueKey('shopping-suggestions'),
            suggestions: AsyncData([
              ShoppingSuggestion(name: 'Milk', brand: 'Farm', purchaseCount: 2),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Purchased 2 times'), findsOneWidget);
      await tester.tap(_suggestion('milk|farm'));
      await tester.pumpAndSettle();
      expect(repository.savedItems.single.name, 'Milk');
      expect(repository.savedItems.single.brand, 'Farm');
      expect(repository.savedItems.single.quantity, 1);
      expect(find.textContaining('Purchased 2 times'), findsNothing);
      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('the cross pushes a suggestion behind the others and the '
        'order is kept on the device', (tester) async {
      final preferences = MemoryAppPreferences();
      const strip = ShoppingListSuggestions(
        suggestions: AsyncData([
          ShoppingSuggestion(name: 'Milk', isOutOfStock: true),
          ShoppingSuggestion(name: 'Oats', isLowStock: true),
          ShoppingSuggestion(name: 'Butter', purchaseCount: 3),
        ]),
      );
      List<String> order() => [
        for (final card in tester.widgetList<ShoppingSuggestionCard>(
          find.byType(ShoppingSuggestionCard),
        ))
          card.suggestion.name,
      ];
      Future<void> pushBack(String key) async {
        await tester.tap(
          find.descendant(
            of: _suggestion(key),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(
        _app(
          _container(FakeShoppingListRepository(), preferences: preferences),
          suggestionStrip: strip,
        ),
      );
      await tester.pumpAndSettle();
      expect(order(), ['Milk', 'Oats', 'Butter']);

      await pushBack('milk|');
      expect(order(), ['Oats', 'Butter', 'Milk']);
      await pushBack('oats|');
      expect(order(), ['Butter', 'Milk', 'Oats']);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _app(
          _container(FakeShoppingListRepository(), preferences: preferences),
          suggestionStrip: strip,
        ),
      );
      await tester.pumpAndSettle();
      expect(order(), ['Butter', 'Milk', 'Oats']);
    });

    testWidgets('many suggestions with long names scroll sideways without '
        'overflow at large text', (tester) async {
      await _setView(tester, const Size(360, 800));
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: _app(
            _container(FakeShoppingListRepository()),
            suggestionStrip: ShoppingListSuggestions(
              suggestions: AsyncData([
                for (var index = 0; index < 20; index++)
                  ShoppingSuggestion(
                    name: 'Frische Bio-Alpenmilch 3,5 % Fett Nummer $index',
                    brand: 'Berchtesgadener Land',
                    isLowStock: true,
                  ),
              ]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byKey(ShoppingListPageKeys.suggestionStrip),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed suggestion save restores suggestion and shows error', (
      tester,
    ) async {
      final repository = FakeShoppingListRepository()
        ..saveAllShouldFail = true
        ..saveDelay = const Duration(milliseconds: 500);
      final container = _container(repository);
      await tester.pumpWidget(
        _app(
          container,
          suggestionStrip: const ShoppingListSuggestions(
            key: ValueKey('shopping-suggestions'),
            suggestions: AsyncData([
              ShoppingSuggestion(name: 'Milk', brand: 'Farm', purchaseCount: 2),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_suggestion('milk|farm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.textContaining('Purchased 2 times'), findsOneWidget);
      expect(find.byType(AppSnackBarView), findsOneWidget);
      expect(
        container.read(shoppingListControllerProvider).requireValue,
        isEmpty,
      );
    });
  });

  group('progress and cart', () {
    testWidgets('counts the entries in the cart against all entries', (
      tester,
    ) async {
      await _pump(tester, [
        _item('milk'),
        _item('bread', isDone: true),
        _item('eggs'),
        _item('archived').copyWith(isArchived: true),
      ]);

      expect(_progress(tester), '1 of 3 in the cart');
      expect(_tile('milk'), findsOneWidget);
      expect(_tile('eggs'), findsOneWidget);
      expect(_tile('bread'), findsNothing);
      expect(_chip('bread'), findsOneWidget);
      expect(_tile('archived'), findsNothing);
      expect(_chip('archived'), findsNothing);
    });

    testWidgets('a tap ticks the entry, it lingers, then moves to the cart', (
      tester,
    ) async {
      final repository = await _pump(tester, [_item('milk'), _item('eggs')]);

      await tester.tap(_tile('milk'));
      await tester.pump();

      expect(_saved(repository, 'milk').isDone, isTrue);
      expect(_progress(tester), '1 of 2 in the cart');
      expect(_tile('milk'), findsOneWidget);
      expect(_chip('milk'), findsNothing);

      await tester.pump(
        AppShopping.tickLinger - const Duration(milliseconds: 1),
      );
      expect(_tile('milk'), findsOneWidget);
      expect(_chip('milk'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(_tile('milk'), findsNothing);
      expect(_chip('milk'), findsOneWidget);
      expect(_tile('eggs'), findsOneWidget);
      expect(_progress(tester), '1 of 2 in the cart');
    });

    testWidgets('a second tap while the tile lingers takes the tick back', (
      tester,
    ) async {
      final repository = await _pump(tester, [_item('milk')]);

      await tester.tap(_tile('milk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(_tile('milk'));
      await tester.pump();

      expect(_saved(repository, 'milk').isDone, isFalse);
      expect(_progress(tester), '0 of 1 in the cart');

      await tester.pump(AppShopping.tickLinger * 2);
      await tester.pump();

      expect(_tile('milk'), findsOneWidget);
      expect(_chip('milk'), findsNothing);
    });

    testWidgets('a second tap takes the tick back while the first save is '
        'still on its way', (tester) async {
      final repository = await _pump(tester, [_item('milk')]);
      repository.saveDelay = const Duration(seconds: 2);

      await tester.tap(_tile('milk'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_progress(tester), '1 of 1 in the cart');
      await tester.tap(_tile('milk'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(_tile('milk'), findsOneWidget);
      expect(_chip('milk'), findsNothing);
      expect(_saved(repository, 'milk').isDone, isFalse);
    });

    testWidgets('a saved product in the cart can be added again', (
      tester,
    ) async {
      final repository = await _pump(tester, [
        _item('milk', quantity: 2, isDone: true, isFavorite: true),
      ]);

      await tester.ensureVisible(find.byTooltip('Add item').last);
      await tester.tap(find.byTooltip('Add item').last);
      await tester.pumpAndSettle();

      expect(_tile('milk'), findsOneWidget);
      expect(
        (
          _saved(repository, 'milk').isDone,
          _saved(repository, 'milk').quantity,
        ),
        (false, 2),
      );
    });

    testWidgets('a cart chip puts the entry back on the list', (tester) async {
      final repository = await _pump(tester, [_item('milk', isDone: true)]);

      await tester.tap(_chip('milk'));
      await tester.pump();
      await tester.pump();

      expect(_saved(repository, 'milk').isDone, isFalse);
      expect(_chip('milk'), findsNothing);
      expect(_tile('milk'), findsOneWidget);
      expect(_progress(tester), '0 of 1 in the cart');
    });

    testWidgets('a put back entry does not linger as ticked', (tester) async {
      await _pump(tester, [_item('milk', isDone: true)]);

      await tester.tap(_chip('milk'));
      await tester.pump();
      await tester.pump();
      await tester.pump(AppShopping.tickLinger * 2);

      expect(_tile('milk'), findsOneWidget);
      expect(_chip('milk'), findsNothing);
    });

    testWidgets('the quantity badge shows only above one', (tester) async {
      await _pump(tester, [_item('milk', quantity: 3), _item('eggs')]);

      expect(find.byKey(ShoppingListPageKeys.tileQuantity('milk')), findsOne);
      expect(
        tester
            .widget<Text>(find.byKey(ShoppingListPageKeys.tileQuantity('milk')))
            .data,
        '3',
      );
      expect(
        find.byKey(ShoppingListPageKeys.tileQuantity('eggs')),
        findsNothing,
      );
    });

    testWidgets('the quantity survives ticking off and putting back', (
      tester,
    ) async {
      final repository = await _pump(tester, [_item('milk', quantity: 3)]);

      await _tick(tester, 'milk');

      expect(_saved(repository, 'milk').quantity, 3);
      expect(find.text('3× milk'), findsOneWidget);

      await tester.tap(_chip('milk'));
      await tester.pump();
      await tester.pump();

      expect(_saved(repository, 'milk').quantity, 3);
      expect(_saved(repository, 'milk').isDone, isFalse);
      expect(
        tester
            .widget<Text>(find.byKey(ShoppingListPageKeys.tileQuantity('milk')))
            .data,
        '3',
      );
    });

    testWidgets('a failed save shows the message and the tile returns', (
      tester,
    ) async {
      final repository = await _pump(tester, [_item('milk')]);
      repository.saveAllShouldFail = true;

      await tester.tap(_tile('milk'));
      await tester.pump();
      await tester.pump();
      await tester.pump(AppShopping.tickLinger);
      await tester.pump();

      expect(find.byType(AppSnackBarView), findsOneWidget);
      expect(find.text('Could not save the shopping list.'), findsOneWidget);
      expect(_tile('milk'), findsOneWidget);
      expect(_chip('milk'), findsNothing);
      expect(_progress(tester), '0 of 1 in the cart');
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });
  });

  group('finish', () {
    testWidgets('is disabled while the cart is empty', (tester) async {
      await _pump(tester, [_item('milk')]);

      final button = tester.widget<FilledButton>(
        find.byKey(ShoppingListPageKeys.finishButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('confirm removes the entries in the cart only', (tester) async {
      final repository = await _pump(tester, [
        _item('milk', isDone: true),
        _item('eggs'),
      ]);

      await tester.tap(find.byKey(ShoppingListPageKeys.finishButton));
      await tester.pumpAndSettle();
      expect(find.text('1 item in the cart leaves the list.'), findsOneWidget);
      await tester.tap(find.byKey(ShoppingListPageKeys.finishConfirmButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.savedItems.map((item) => item.id), ['eggs']);
      expect(_chip('milk'), findsNothing);
      expect(_tile('eggs'), findsOneWidget);
      expect(_progress(tester), '0 of 1 in the cart');
    });

    testWidgets('confirm archives a favorite instead of dropping it', (
      tester,
    ) async {
      final repository = await _pump(tester, [
        _item('milk', isDone: true, isFavorite: true),
      ]);

      await tester.tap(find.byKey(ShoppingListPageKeys.finishButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ShoppingListPageKeys.finishConfirmButton));
      await tester.pumpAndSettle();

      final milk = repository.savedItems.single;
      expect((milk.id, milk.isArchived, milk.isFavorite), ('milk', true, true));
      expect(_chip('milk'), findsNothing);
      expect(find.text('Your shopping list is empty.'), findsOneWidget);
    });

    testWidgets('cancel keeps the cart', (tester) async {
      final repository = await _pump(tester, [_item('milk', isDone: true)]);

      await tester.tap(find.byKey(ShoppingListPageKeys.finishButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ShoppingListPageKeys.finishCancelButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.savedItems, isEmpty);
      expect(_chip('milk'), findsOneWidget);
    });
  });

  group('entry sheet', () {
    testWidgets('a long press opens it with the quantity', (tester) async {
      await _pump(tester, [_item('milk', quantity: 2)]);

      await _openSheet(tester, 'milk');

      expect(_sheetQuantity(tester), '2');
      expect(find.byKey(ShoppingListPageKeys.sheetSchedule), findsOneWidget);
      expect(find.byKey(ShoppingListPageKeys.sheetFavorite), findsOneWidget);
    });

    testWidgets('increase and decrease change the quantity', (tester) async {
      final repository = await _pump(tester, [_item('milk', quantity: 2)]);
      await _openSheet(tester, 'milk');

      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pumpAndSettle();
      expect(_sheetQuantity(tester), '3');
      expect(_saved(repository, 'milk').quantity, 3);
      expect(
        tester
            .widget<Text>(find.byKey(ShoppingListPageKeys.tileQuantity('milk')))
            .data,
        '3',
      );

      await tester.tap(find.byTooltip('Decrease quantity'));
      await tester.pumpAndSettle();
      expect(_sheetQuantity(tester), '2');
      expect(_saved(repository, 'milk').quantity, 2);
    });

    testWidgets('decrease is disabled at one', (tester) async {
      final repository = await _pump(tester, [_item('milk')]);
      await _openSheet(tester, 'milk');

      final decrease = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
      );
      expect(decrease.onPressed, isNull);

      await tester.tap(find.byTooltip('Decrease quantity'));
      await tester.pumpAndSettle();
      expect(_sheetQuantity(tester), '1');
      expect(repository.savedItems, isEmpty);
    });

    testWidgets('the favorite switch saves and drops the favorite', (
      tester,
    ) async {
      final repository = await _pump(tester, [_item('milk')]);
      await _openSheet(tester, 'milk');

      await tester.tap(find.byKey(ShoppingListPageKeys.sheetFavorite));
      await tester.pumpAndSettle();
      expect(_saved(repository, 'milk').isFavorite, isTrue);
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(ShoppingListPageKeys.sheetFavorite),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isTrue,
      );

      await tester.tap(find.byKey(ShoppingListPageKeys.sheetFavorite));
      await tester.pumpAndSettle();
      expect(_saved(repository, 'milk').isFavorite, isFalse);
    });

    testWidgets('the cart button moves the entry to the cart and closes', (
      tester,
    ) async {
      final repository = await _pump(tester, [_item('milk', quantity: 2)]);
      await _openSheet(tester, 'milk');

      await tester.tap(find.byKey(ShoppingListPageKeys.sheetCartButton));
      await tester.pumpAndSettle();

      expect(find.byKey(ShoppingListPageKeys.sheetCartButton), findsNothing);
      expect(_saved(repository, 'milk').isDone, isTrue);
      expect(_saved(repository, 'milk').quantity, 2);
      expect(_chip('milk'), findsOneWidget);
      expect(_tile('milk'), findsNothing);
    });

    testWidgets('the cart button puts a lingering entry back and closes', (
      tester,
    ) async {
      final repository = await _pump(tester, [_item('milk')]);
      await tester.tap(_tile('milk'));
      await tester.pump();
      await tester.longPress(_tile('milk'));
      await tester.pumpAndSettle();
      expect(find.text('Back onto the list'), findsOneWidget);

      await tester.tap(find.byKey(ShoppingListPageKeys.sheetCartButton));
      await tester.pumpAndSettle();

      expect(find.byKey(ShoppingListPageKeys.sheetCartButton), findsNothing);
      expect(_saved(repository, 'milk').isDone, isFalse);
      expect(_tile('milk'), findsOneWidget);
      expect(_chip('milk'), findsNothing);
    });

    testWidgets('the remove button takes the entry off the list and closes', (
      tester,
    ) async {
      final repository = await _pump(tester, [_item('milk'), _item('eggs')]);
      await _openSheet(tester, 'milk');

      await tester.tap(find.byKey(ShoppingListPageKeys.sheetRemoveButton));
      await tester.pumpAndSettle();

      expect(find.byKey(ShoppingListPageKeys.sheetRemoveButton), findsNothing);
      expect(repository.savedItems.map((item) => item.id), ['eggs']);
      expect(_tile('milk'), findsNothing);
      expect(_progress(tester), '0 of 1 in the cart');
    });

    testWidgets('a failed save in the sheet shows the message', (tester) async {
      final repository = await _pump(tester, [_item('milk')]);
      await _openSheet(tester, 'milk');
      repository.saveAllShouldFail = true;

      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Could not save the shopping list.'), findsOneWidget);
      expect(_sheetQuantity(tester), '1');
    });
  });

  group('layout', () {
    double top(WidgetTester tester, String id) =>
        tester.getTopLeft(_tile(id)).dy;

    testWidgets('three tiles share a row at normal text size', (tester) async {
      await _pumpScaled(tester, [
        _item('a'),
        _item('b'),
        _item('c'),
        _item('d'),
      ], scale: 1);

      expect(top(tester, 'b'), top(tester, 'a'));
      expect(top(tester, 'c'), top(tester, 'a'));
      expect(top(tester, 'd'), greaterThan(top(tester, 'a')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('two tiles share a row at large text size', (tester) async {
      await _pumpScaled(tester, [
        _item('a'),
        _item('b'),
        _item('c'),
        _item('d'),
      ], scale: 2);

      expect(top(tester, 'b'), top(tester, 'a'));
      expect(top(tester, 'c'), greaterThan(top(tester, 'a')));
      expect(top(tester, 'd'), top(tester, 'c'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a narrow screen uses two tiles per row', (tester) async {
      await _setView(tester, const Size(320, 800));
      await _pump(tester, [_item('a'), _item('b'), _item('c')]);

      expect(top(tester, 'b'), top(tester, 'a'));
      expect(top(tester, 'c'), greaterThan(top(tester, 'a')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long name and brand do not overflow at large text', (
      tester,
    ) async {
      await _pumpScaled(tester, [
        _item(
          'bread',
          name: 'Whole grain bread with sunflower seeds and pumpkin seeds',
          quantity: 12,
        ).copyWith(brand: 'The Very Long Bakery Brand Name'),
        _item('milk', quantity: 2),
        _item('eggs', isDone: true, quantity: 24),
      ], scale: 2);

      expect(tester.takeException(), isNull);
      expect(_tile('bread'), findsOneWidget);
      expect(_chip('eggs'), findsOneWidget);
    });

    testWidgets('a long name does not overflow at normal text size', (
      tester,
    ) async {
      await _pumpScaled(tester, [
        _item(
          'bread',
          name: 'Whole grain bread with sunflower seeds and pumpkin seeds',
        ),
        _item('milk'),
        _item('eggs'),
      ], scale: 1);

      expect(tester.takeException(), isNull);
    });
  });
}
