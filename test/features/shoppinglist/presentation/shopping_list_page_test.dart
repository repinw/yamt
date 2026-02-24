import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_stats_card.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ShoppingListPage()),
    ),
  );
}

String _statValue(WidgetTester tester, Key key) {
  final text = tester.widget<Text>(find.byKey(key));
  return text.data ?? '';
}

void _addItem(
  ProviderContainer container, {
  required String name,
  String? brand,
  int quantity = 1,
}) {
  final controller = container.read(shoppingListControllerProvider.notifier);
  controller.addItem(name: name, brand: brand, quantity: quantity);
}

void main() {
  testWidgets('shows empty state initially', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));

    expect(find.text('Your shopping list is empty.'), findsOneWidget);
  });

  testWidgets('does not render inline add form', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('updates stats values when list changes', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    _addItem(container, name: 'Bread');

    await tester.pumpWidget(_wrap(container));
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
    final container = ProviderContainer();
    addTearDown(container.dispose);
    _addItem(container, name: 'Bread');

    await tester.pumpWidget(_wrap(container));
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
    final container = ProviderContainer();
    addTearDown(container.dispose);
    _addItem(container, name: 'Bread', quantity: 1);

    await tester.pumpWidget(_wrap(container));
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
    final container = ProviderContainer();
    addTearDown(container.dispose);
    _addItem(container, name: 'Bread', quantity: 1);

    await tester.pumpWidget(_wrap(container));
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
    final container = ProviderContainer();
    addTearDown(container.dispose);
    _addItem(container, name: 'Bread', quantity: 1);

    await tester.pumpWidget(_wrap(container));
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
