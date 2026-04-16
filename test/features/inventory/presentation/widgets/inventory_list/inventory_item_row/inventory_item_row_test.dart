import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/remaining_progress_bar.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_primary_action_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

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
                        showBarcodeMarkers: false,
                        isAlreadyInShoppingList: false,
                        onDeletePressed: (itemId) async => true,
                        onEatPressed: (itemId, amount) async => true,
                        onThrowAwayPressed: (itemId, amount, reason) async =>
                            true,
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
      unitPrice: 1.0,
      brand: 'Acme',
    );
  }
}

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
      find.byType(InventoryPrimaryActionButton),
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

    expect(find.text('Delete'), findsOneWidget);

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: false, bucket: bucket),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _InventoryItemRowHost(showRow: true, bucket: bucket),
    );
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
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
      unitPrice: 1.0,
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
