import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrap() {
  return const ProviderScope(
    child: MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ShoppingListPage()),
    ),
  );
}

void main() {
  testWidgets('shows empty state initially', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('Your shopping list is empty.'), findsOneWidget);
  });

  testWidgets('adds item and merges duplicate input', (tester) async {
    await tester.pumpWidget(_wrap());

    await tester.enterText(find.byKey(ShoppingListPageKeys.nameField), 'Milk');
    await tester.enterText(find.byKey(ShoppingListPageKeys.brandField), 'Acme');
    await tester.tap(find.byKey(ShoppingListPageKeys.addButton));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.textContaining('Qty: 1'), findsOneWidget);

    await tester.enterText(
      find.byKey(ShoppingListPageKeys.nameField),
      ' milk ',
    );
    await tester.enterText(
      find.byKey(ShoppingListPageKeys.brandField),
      ' acme ',
    );
    await tester.tap(find.byKey(ShoppingListPageKeys.addButton));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.textContaining('Qty: 2'), findsOneWidget);
  });

  testWidgets('supports swipe-to-delete and quantity stepper', (tester) async {
    await tester.pumpWidget(_wrap());

    await tester.enterText(find.byKey(ShoppingListPageKeys.nameField), 'Bread');
    await tester.tap(find.byKey(ShoppingListPageKeys.addButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('Qty: 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Qty: 2'), findsOneWidget);

    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Bread'), findsNothing);
  });
}
