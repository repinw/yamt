import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

FridgeItem _item(
  String id, {
  required String name,
  required String storeName,
  required String receiptId,
  required DateTime receiptDate,
  int quantity = 1,
  double unitPrice = 1.0,
}) {
  return FridgeItem(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: storeName,
    quantity: quantity,
    initialQuantity: quantity,
    unitPrice: unitPrice,
    receiptId: receiptId,
    receiptDate: receiptDate,
  );
}

InventoryReceiptGroup _group() {
  return InventoryReceiptGroup.fromItems('receipt:abc123', <FridgeItem>[
    _item(
      'a',
      name: 'Milk',
      storeName: 'Aldi',
      receiptId: 'abc123',
      receiptDate: DateTime.parse('2026-02-20T10:00:00Z'),
      quantity: 1,
      unitPrice: 1.5,
    ),
    _item(
      'b',
      name: 'Bread',
      storeName: 'Aldi',
      receiptId: 'abc123',
      receiptDate: DateTime.parse('2026-02-20T10:00:00Z'),
      quantity: 2,
      unitPrice: 2.0,
    ),
  ]);
}

Widget _buildHarness({
  required ThemeData theme,
  required InventoryReceiptGroup group,
  Future<bool> Function(String itemId)? onDeleteItem,
  Future<bool> Function(String itemId, int amount)? onEatItem,
  Future<bool> Function(String itemId, int amount)? onThrowAwayItem,
}) {
  final localeTag = const Locale('en').toLanguageTag();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: ReceiptGroupTile(
                group: group,
                currency: NumberFormat.currency(locale: localeTag, symbol: '€'),
                dateFormat: DateFormat.yMMMd(localeTag),
                onDeleteItem: onDeleteItem ?? (_) async => true,
                onEatItem: onEatItem ?? (itemId, amount) async => true,
                onThrowAwayItem:
                    onThrowAwayItem ?? (itemId, amount) async => true,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Future<void> _pump(WidgetTester tester, {required ThemeData theme}) async {
  await tester.pumpWidget(_buildHarness(theme: theme, group: _group()));
  await tester.pumpAndSettle();
}

Future<void> _expand(WidgetTester tester) async {
  await tester.tap(find.text('Receipt Feb 20, 2026'));
  await tester.pumpAndSettle();
}

void main() {
  final lightTheme = AppTheme.light(seedColor: AppColors.seed);
  final darkTheme = AppTheme.dark(seedColor: AppColors.seed);

  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  testWidgets('renders without errors in light and dark themes', (
    tester,
  ) async {
    await _pump(tester, theme: lightTheme);
    expect(find.text('Receipt Feb 20, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pump(tester, theme: darkTheme);
    expect(find.text('Receipt Feb 20, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('golden: light collapsed', (tester) async {
    await _pump(tester, theme: lightTheme);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_group_tile_light_collapsed.png'),
    );
  });

  testWidgets('golden: light expanded', (tester) async {
    await _pump(tester, theme: lightTheme);
    await _expand(tester);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_group_tile_light_expanded.png'),
    );
  });

  testWidgets('golden: dark collapsed', (tester) async {
    await _pump(tester, theme: darkTheme);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_group_tile_dark_collapsed.png'),
    );
  });

  testWidgets('golden: dark expanded', (tester) async {
    await _pump(tester, theme: darkTheme);
    await _expand(tester);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_group_tile_dark_expanded.png'),
    );
  });

  testWidgets('expanded tile shows receipt item rows', (tester) async {
    await _pump(tester, theme: lightTheme);
    expect(find.text('Milk'), findsNothing);
    expect(find.text('Bread'), findsNothing);

    await _expand(tester);

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets('triggers onDeleteItem when delete button is pressed', (
    tester,
  ) async {
    String? deletedItemId;
    await tester.pumpWidget(
      _buildHarness(
        theme: lightTheme,
        group: _group(),
        onDeleteItem: (itemId) async {
          deletedItemId = itemId;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _expand(tester);
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deletedItemId, 'a');
  });

  testWidgets('triggers onEatItem when eat action is confirmed', (
    tester,
  ) async {
    String? eatenItemId;
    int? eatenAmount;
    await tester.pumpWidget(
      _buildHarness(
        theme: lightTheme,
        group: _group(),
        onEatItem: (itemId, amount) async {
          eatenItemId = itemId;
          eatenAmount = amount;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _expand(tester);
    await tester.tap(find.byTooltip('Eat').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '1',
    );
    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(eatenItemId, isNotNull);
    expect(<String>['a', 'b'], contains(eatenItemId));
    expect(eatenAmount, 1);
  });

  testWidgets('triggers onThrowAwayItem when action is confirmed', (
    tester,
  ) async {
    String? thrownAwayItemId;
    int? thrownAwayAmount;
    await tester.pumpWidget(
      _buildHarness(
        theme: lightTheme,
        group: _group(),
        onThrowAwayItem: (itemId, amount) async {
          thrownAwayItemId = itemId;
          thrownAwayAmount = amount;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _expand(tester);
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Throw away').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '1',
    );
    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(thrownAwayItemId, 'a');
    expect(thrownAwayAmount, 1);
  });
}
