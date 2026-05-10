import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_primary_action_button.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'remaining_progress_bar.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([inventoryItemRepository, InventoryItemsController])
class _InventoryItemRowHost extends StatelessWidget {
  const _InventoryItemRowHost({
    required this.showRow,
    required this.bucket,
    this.item,
    this.theme,
  });

  final bool showRow;
  final PageStorageBucket bucket;
  final InventoryItem? item;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PageStorage(
          bucket: bucket,
          child: Scaffold(
            body: showRow
                ? Builder(
                    builder: (context) {
                      return InventoryItemRow(
                        expansionStorageKey: 'inventory_item_row_milk',
                        item: item ?? _buildItem(),
                        l10n: AppLocalizations.of(context)!,
                        isAlreadyInShoppingList: false,
                        onDeletePressed: (itemId) async => true,
                        onEatPressed: (itemId, amount) async => true,
                        onThrowAwayPressed: (itemId, amount, reason) async => (
                          discardEventId: 'discard-$itemId',
                          removedAmount: amount,
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  InventoryItem _buildItem() {
    return InventoryItem.create(
      id: 'milk',
      name: 'Milk',
      entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
      storeName: 'Store',
      quantity: 2,
      initialQuantity: 2,
      unitPrice: 1,
      brand: 'Acme',
    );
  }
}

@Dependencies([inventoryItemRepository, InventoryItemsController])
void main() {
  testWidgets('positions expand indicator in the top-right header area', (
    tester,
  ) async {
    final bucket = PageStorageBucket();
    const indicatorKey = Key('inventory_item_row_expand_indicator_milk');

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: true, bucket: bucket),
    );
    await tester.pumpAndSettle();

    final iconCenter = tester.getCenter(find.byType(InventoryItemImageTile));
    final indicatorCenter = tester.getCenter(find.byKey(indicatorKey));
    final progressRect = tester.getRect(find.byType(RemainingProgressBar));

    expect(indicatorCenter.dx, greaterThan(iconCenter.dx));
    expect(indicatorCenter.dy, lessThan(progressRect.top));
  });

  testWidgets(
    'shows progress row below image row and starting from tile edge',
    (tester) async {
      final bucket = PageStorageBucket();

      await tester.pumpWidget(
        _InventoryItemRowHost(showRow: true, bucket: bucket),
      );
      await tester.pumpAndSettle();

      final iconRect = tester.getRect(find.byType(InventoryItemImageTile));
      final progressRect = tester.getRect(find.byType(RemainingProgressBar));

      expect(progressRect.top, greaterThan(iconRect.bottom));
      expect(progressRect.left, lessThanOrEqualTo(iconRect.left));
    },
  );

  testWidgets('uses theme primary color for text action button', (
    tester,
  ) async {
    final bucket = PageStorageBucket();
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
    );

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: true, bucket: bucket, theme: theme),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<InventoryPrimaryActionButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is InventoryPrimaryActionButton &&
            widget.label == 'Eat' &&
            widget.showText,
      ),
    );

    expect(button.enabledBackgroundColor, theme.colorScheme.primary);
    expect(button.useGradientWhenShowText, isFalse);
  });

  testWidgets('shows expand indicator and rotates it on tap', (tester) async {
    final bucket = PageStorageBucket();
    const indicatorKey = Key('inventory_item_row_expand_indicator_milk');

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: true, bucket: bucket),
    );
    await tester.pumpAndSettle();

    final initialRotation = tester.widget<AnimatedRotation>(
      find.byKey(indicatorKey),
    );
    expect(initialRotation.turns, 0);

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    final expandedRotation = tester.widget<AnimatedRotation>(
      find.byKey(indicatorKey),
    );
    expect(expandedRotation.turns, 0.5);
  });

  testWidgets('restores expanded state from page storage after rebuild', (
    tester,
  ) async {
    final bucket = PageStorageBucket();

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: true, bucket: bucket),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(find.text('Remove'), findsOneWidget);

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: false, bucket: bucket),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: true, bucket: bucket),
    );
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('opens the item editor from the expanded edit action', (
    tester,
  ) async {
    final bucket = PageStorageBucket();

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: true, bucket: bucket),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit inventory item'), findsOneWidget);
    expect(find.text('Discounts'), findsNothing);
    expect(find.text('Is deposit item'), findsNothing);
    expect(find.text('Is discount item'), findsNothing);
    expect(find.text('Not implemented yet'), findsNothing);
  });

  testWidgets('skips saving when the expanded edit action returns no changes', (
    tester,
  ) async {
    final bucket = PageStorageBucket();

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: true, bucket: bucket),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Apply changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply changes'));
    await tester.pumpAndSettle();

    expect(find.text('Edit inventory item'), findsNothing);
    expect(find.text('Inventory item updated.'), findsNothing);
    expect(find.text('Action failed. Please try again.'), findsNothing);
  });

  testWidgets('shows a snackbar instead of editing non-full items', (
    tester,
  ) async {
    final bucket = PageStorageBucket();
    final partialItem =
        InventoryItem.create(
              id: 'milk',
              name: 'Milk',
              entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
              storeName: 'Store',
              quantity: 1,
              weight: '500g',
            )
            .withDerivedAmount(weight: '500g', quantity: 1)
            .copyWith(
              currentAmount: 250,
            );

    await tester.pumpWidget(
      _InventoryItemRowHost(
        showRow: true,
        bucket: bucket,
        item: partialItem,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    final editButtonFinder = find.ancestor(
      of: find.text('Edit'),
      matching: find.byType(TextButton),
    );
    final editButton = tester.widget<TextButton>(editButtonFinder);

    expect(editButton.onPressed, isNotNull);

    await tester.tap(find.text('Edit'));
    await tester.pump();

    expect(
      find.text(
        'You can edit the item only while it is still fully available.',
      ),
      findsOneWidget,
    );
    expect(find.text('Edit inventory item'), findsNothing);
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('shows nutrition metrics inside one segmented strip', (
    tester,
  ) async {
    final bucket = PageStorageBucket();
    final itemWithNutrition = InventoryItem.create(
      id: 'milk',
      name: 'Milk',
      entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
      storeName: 'Store',
      quantity: 2,
      initialQuantity: 2,
      unitPrice: 1,
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 590,
        per100Carbs: 36,
        per100Protein: 100,
        per100Fat: 0,
      ),
    );

    await tester.pumpWidget(
      _InventoryItemRowHost(
        showRow: true,
        bucket: bucket,
        item: itemWithNutrition,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(find.text('KCAL'), findsOneWidget);
    expect(find.text('CARBS'), findsOneWidget);
    expect(find.text('PROTEIN'), findsOneWidget);
    expect(find.text('FAT'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNWidgets(3));
  });
}
