import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _item(
  String id, {
  required String name,
  required String storeName,
  required String receiptId,
  required DateTime receiptDate,
  int quantity = 1,
  double unitPrice = 1.0,
  String? currencyCode,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: storeName,
    quantity: quantity,
    initialQuantity: quantity,
    unitPrice: unitPrice,
    currencyCode: currencyCode,
    receiptId: receiptId,
    receiptDate: receiptDate,
  );
}

InventoryReceiptGroup _group() {
  return InventoryReceiptGroup.fromItems('receipt:abc123', <InventoryItem>[
    _item(
      'a',
      name: 'Milk',
      storeName: 'Aldi',
      receiptId: 'abc123',
      receiptDate: DateTime.parse('2026-02-20T10:00:00Z'),
      quantity: 1,
      unitPrice: 1.5,
      currencyCode: 'EUR',
    ),
    _item(
      'b',
      name: 'Bread',
      storeName: 'Aldi',
      receiptId: 'abc123',
      receiptDate: DateTime.parse('2026-02-20T10:00:00Z'),
      quantity: 2,
      unitPrice: 2.0,
      currencyCode: 'EUR',
    ),
  ]);
}

Widget _buildHarness({
  required ThemeData theme,
  required InventoryReceiptGroup group,
  PageStorageBucket? bucket,
  bool showTile = true,
  Future<bool> Function(String itemId)? onDeleteItem,
  Future<bool> Function(String itemId, InventoryItemEatRequest request)?
  onEatItem,
  Future<bool> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )?
  onThrowAwayItem,
}) {
  final tile = ReceiptGroupTile(
    group: group,
    dateFormat: DateFormat.yMMMd(const Locale('en').toLanguageTag()),
    showBarcodeMarkers: false,
    activeShoppingListItemKeys: const <ShoppingListItemMatchKey>{},
    onDeleteItem: onDeleteItem ?? (_) async => true,
    onEatItem: onEatItem ?? (itemId, request) async => true,
    onThrowAwayItem: onThrowAwayItem ?? (itemId, amount, reason) async => true,
  );
  final body = SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Center(
      child: SizedBox(
        width: 360,
        child: showTile ? tile : const SizedBox.shrink(),
      ),
    ),
  );
  final scaffoldBody = bucket == null
      ? body
      : PageStorage(bucket: bucket, child: body);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: scaffoldBody),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      barcodeBackfillFeatureFlagsProvider.overrideWithValue(
        const BarcodeBackfillFeatureFlags(
          showInventoryBarcodeMarkers: false,
          enableQueueBackfill: true,
        ),
      ),
    ],
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

Future<void> _toggleExpansion(WidgetTester tester) async {
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
    expect(find.text('Milk'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pump(tester, theme: darkTheme);
    expect(find.text('Receipt Feb 20, 2026'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('light theme shows item count pill', (tester) async {
    await _pump(tester, theme: lightTheme);
    expect(find.text('2 ITEMS'), findsOneWidget);
  });

  testWidgets('dark theme shows item count pill', (tester) async {
    await _pump(tester, theme: darkTheme);
    expect(find.text('2 ITEMS'), findsOneWidget);
  });

  testWidgets('shows expand indicator and rotates it on tap', (tester) async {
    const indicatorKey = Key('receipt_group_expand_indicator_receipt:abc123');

    await _pump(tester, theme: lightTheme);

    final initialRotation = tester.widget<AnimatedRotation>(
      find.byKey(indicatorKey),
    );
    expect(initialRotation.turns, 0.5);

    await _toggleExpansion(tester);

    final collapsedRotation = tester.widget<AnimatedRotation>(
      find.byKey(indicatorKey),
    );
    expect(collapsedRotation.turns, 0);
  });

  testWidgets('golden: light collapsed', (tester) async {
    await _pump(tester, theme: lightTheme);
    await _toggleExpansion(tester);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_group_tile_light_collapsed.png'),
    );
  });

  testWidgets('golden: light expanded', (tester) async {
    await _pump(tester, theme: lightTheme);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_group_tile_light_expanded.png'),
    );
  });

  testWidgets('golden: dark collapsed', (tester) async {
    await _pump(tester, theme: darkTheme);
    await _toggleExpansion(tester);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_group_tile_dark_collapsed.png'),
    );
  });

  testWidgets('golden: dark expanded', (tester) async {
    await _pump(tester, theme: darkTheme);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_group_tile_dark_expanded.png'),
    );
  });

  testWidgets('expanded tile shows receipt item rows', (tester) async {
    await _pump(tester, theme: lightTheme);

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets('collapsed tile does not build receipt row entries', (
    tester,
  ) async {
    await _pump(tester, theme: lightTheme);
    await _toggleExpansion(tester);

    expect(find.byType(InventoryItemRowListEntry), findsNothing);
  });

  testWidgets('expanding tile lazily builds receipt row entries', (
    tester,
  ) async {
    await _pump(tester, theme: lightTheme);
    await _toggleExpansion(tester);

    await _toggleExpansion(tester);

    expect(find.byType(InventoryItemRowListEntry), findsNWidgets(2));
  });

  testWidgets('restores expansion state from PageStorage', (tester) async {
    final bucket = PageStorageBucket();

    await tester.pumpWidget(
      _buildHarness(theme: lightTheme, group: _group(), bucket: bucket),
    );
    await tester.pumpAndSettle();

    await _toggleExpansion(tester);
    expect(find.byType(InventoryItemRowListEntry), findsNothing);

    await tester.pumpWidget(
      _buildHarness(
        theme: lightTheme,
        group: _group(),
        bucket: bucket,
        showTile: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _buildHarness(theme: lightTheme, group: _group(), bucket: bucket),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InventoryItemRowListEntry), findsNothing);
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
    InventoryItemEatRequest? eatRequest;
    await tester.pumpWidget(
      _buildHarness(
        theme: lightTheme,
        group: _group(),
        onEatItem: (itemId, request) async {
          eatenItemId = itemId;
          eatenAmount = request.inventoryAmount;
          eatRequest = request;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eat').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '1',
    );
    await tester.enterText(find.byType(TextField).last, '25');
    await tester.ensureVisible(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(eatenItemId, isNotNull);
    expect(<String>['a', 'b'], contains(eatenItemId));
    expect(eatenAmount, 1);
    expect(eatRequest?.calorieAmount, 25);
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
        onThrowAwayItem: (itemId, amount, reason) async {
          thrownAwayItemId = itemId;
          thrownAwayAmount = amount;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

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
    await tester.tap(find.text('Expired'));
    await tester.pumpAndSettle();

    expect(thrownAwayItemId, 'a');
    expect(thrownAwayAmount, 1);
  });
}
