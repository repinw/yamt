import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _RecordingInventoryItemsController extends InventoryItemsController {
  _RecordingInventoryItemsController({List<InventoryItem>? initialItems})
    : _initialItems = initialItems ?? const <InventoryItem>[];

  final List<InventoryItem> _initialItems;
  final List<String> discardedPendingIds = <String>[];

  @override
  Future<List<InventoryItem>> build() async => _initialItems;

  @override
  Future<bool> discardPendingConsumption(String draftId) async {
    discardedPendingIds.add(draftId);
    return true;
  }
}

class _EatButton extends ConsumerWidget {
  const _EatButton({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        InventoryCalorieBridgeFlow.onEatCompleted(
          context: context,
          ref: ref,
          itemBeforeMutation: item,
          consumedAmount: 250,
          pendingConsumptionId: 'pending-1',
        );
      },
      child: const Text('eat'),
    );
  }
}

InventoryItem _amountItemWithNutrition({
  String id = 'item-1',
  String? barcode = '4061458029995',
}) {
  return InventoryItem.create(
    id: id,
    globalFoodItemId: 'off-4061458029995',
    name: 'Waffelhörnchen Haselnuss-Vanille',
    brand: 'Mucci',
    barcode: barcode,
    imageUrl: 'https://example.com/waffel.png',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 215,
      per100Protein: 4.2,
      per100Carbs: 24.8,
      per100Fat: 9.6,
    ),
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Aldi',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _portionItemWithNutrition() {
  return InventoryItem.create(
    id: 'item-portion',
    name: 'Milk',
    brand: 'Brand',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 42,
      per100Protein: 3.4,
      per100Carbs: 4.9,
      per100Fat: 1.5,
    ),
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
  );
}

InventoryItem _itemWithoutNutrition() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    brand: 'Brand',
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

void main() {
  testWidgets('eat flow opens calorie editor from local inventory nutrition', (
    tester,
  ) async {
    CalorieEntryCreateArgs? openedArgs;
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) {
            return Scaffold(body: _EatButton(item: _amountItemWithNutrition()));
          },
        ),
        GoRoute(
          path: AppRoutes.homeCaloriesEntryCreate,
          builder: (context, state) {
            openedArgs = state.extra as CalorieEntryCreateArgs?;
            return const Scaffold(body: Text('editor'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();

    expect(openedArgs, isNotNull);
    expect(openedArgs?.prefilledProfile, isNotNull);
    expect(openedArgs?.prefilledProfile?.barcode, '4061458029995');
    expect(openedArgs?.prefilledProfile?.per100Kcal, 215);
    expect(openedArgs?.prefilledProfile?.per100Protein, 4.2);
    expect(openedArgs?.prefilledProfile?.per100Carbs, 24.8);
    expect(openedArgs?.prefilledProfile?.per100Fat, 9.6);
    expect(openedArgs?.inventoryContext?.inventoryItemId, 'item-1');
    expect(openedArgs?.inventoryContext?.inventoryAmountToRestore, 250);
    expect(openedArgs?.inventoryContext?.consumedAmount, 250);
    expect(openedArgs?.inventoryContext?.consumedUnit, ConsumedUnit.grams);
    expect(openedArgs?.scannedSourceRef?.barcode, '4061458029995');
    expect(openedArgs?.scannedSourceRef?.offProductId, 'off-4061458029995');
  });

  testWidgets('eat flow uses synthetic barcode when item has no barcode', (
    tester,
  ) async {
    CalorieEntryCreateArgs? openedArgs;
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) {
            return Scaffold(
              body: _EatButton(item: _amountItemWithNutrition(barcode: null)),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.homeCaloriesEntryCreate,
          builder: (context, state) {
            openedArgs = state.extra as CalorieEntryCreateArgs?;
            return const Scaffold(body: Text('editor'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();

    expect(openedArgs?.prefilledProfile?.barcode, 'inventory-item-1');
    expect(openedArgs?.scannedSourceRef, isNull);
  });

  testWidgets(
    'eat flow asks for manual portion when item is not amount based',
    (tester) async {
      CalorieEntryCreateArgs? openedArgs;
      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) {
              return Scaffold(
                body: _EatButton(item: _portionItemWithNutrition()),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.homeCaloriesEntryCreate,
            builder: (context, state) {
              openedArgs = state.extra as CalorieEntryCreateArgs?;
              return const Scaffold(body: Text('editor'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      await tester.tap(find.text('eat'));
      await tester.pumpAndSettle();

      expect(find.text('Verzehrte Menge eingeben'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '2,5');
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(openedArgs?.inventoryContext?.consumedAmount, 2.5);
      expect(openedArgs?.inventoryContext?.consumedUnit, ConsumedUnit.grams);
    },
  );

  testWidgets(
    'missing local nutrition discards pending consumption and shows feedback',
    (tester) async {
      final inventoryController = _RecordingInventoryItemsController();
      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) {
              return Scaffold(body: _EatButton(item: _itemWithoutNutrition()));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryItemsControllerProvider.overrideWith(
              () => inventoryController,
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('eat'));
      await tester.pumpAndSettle();

      expect(inventoryController.discardedPendingIds, <String>['pending-1']);
      expect(
        find.text('Aktion fehlgeschlagen. Bitte erneut versuchen.'),
        findsOneWidget,
      );
    },
  );
}
