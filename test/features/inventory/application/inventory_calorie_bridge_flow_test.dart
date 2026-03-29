import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _RecordingLookupRepository
    implements CalorieProductLookupRepositoryContract {
  _RecordingLookupRepository({this.onLookupByBarcode});

  int lookupCalls = 0;
  final Future<CalorieLookupOutcome> Function(String rawBarcode)?
  onLookupByBarcode;

  @override
  Future<CalorieLookupOutcome> lookupByBarcode(String rawBarcode) async {
    lookupCalls += 1;
    final callback = onLookupByBarcode;
    if (callback != null) {
      return callback(rawBarcode);
    }
    return const CalorieLookupOutcome.failed(errorCode: 'unexpected_lookup');
  }

  @override
  Future<bool> persistGlobalProduct(CalorieProductProfile profile) async {
    return true;
  }
}

class _RecordingInventoryItemsController extends InventoryItemsController {
  _RecordingInventoryItemsController({List<InventoryItem>? initialItems})
    : _initialItems = initialItems ?? const <InventoryItem>[];

  final List<InventoryItem> _initialItems;
  final List<String> discardedPendingIds = <String>[];

  @override
  FutureOr<List<InventoryItem>> build() => _initialItems;

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

InventoryItem _itemWithNutrition() {
  return InventoryItem.create(
    id: 'inventory-1',
    globalFoodItemId: 'off-4061458029995',
    name: 'Waffelhoernchen Haselnuss-Vanille',
    brand: 'Mucci',
    barcode: '4061458029995',
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

InventoryItem _itemWithoutNutrition({String? barcode}) {
  return InventoryItem.create(
    id: 'inventory-1',
    name: 'Milk',
    brand: 'Brand',
    barcode: barcode,
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

void main() {
  testWidgets('eat flow opens calorie editor from inventory nutrition '
      'without barcode lookup', (tester) async {
    final lookupRepository = _RecordingLookupRepository();
    CalorieEntryCreateArgs? openedArgs;
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) {
            return Scaffold(body: _EatButton(item: _itemWithNutrition()));
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
        overrides: <Override>[
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: false,
              enableEatBridge: true,
              enableQueueBackfill: true,
            ),
          ),
          calorieProductLookupRepositoryProvider.overrideWithValue(
            lookupRepository,
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

    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();

    expect(lookupRepository.lookupCalls, 0);
    expect(openedArgs, isNotNull);
    expect(openedArgs?.prefilledProfile, isNotNull);
    expect(openedArgs?.prefilledProfile?.barcode, '4061458029995');
    expect(openedArgs?.prefilledProfile?.per100Kcal, 215);
    expect(openedArgs?.prefilledProfile?.per100Protein, 4.2);
    expect(openedArgs?.prefilledProfile?.per100Carbs, 24.8);
    expect(openedArgs?.prefilledProfile?.per100Fat, 9.6);
    expect(openedArgs?.inventoryContext?.inventoryItemId, 'inventory-1');
    expect(openedArgs?.inventoryContext?.inventoryAmountToRestore, 250);
    expect(openedArgs?.inventoryContext?.consumedAmount, 250);
    expect(openedArgs?.inventoryContext?.consumedUnit, ConsumedUnit.grams);
    expect(openedArgs?.scannedSourceRef?.barcode, '4061458029995');
    expect(openedArgs?.scannedSourceRef?.offProductId, 'off-4061458029995');
  });

  testWidgets('closing missing-barcode sheet discards pending consumption', (
    tester,
  ) async {
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
        overrides: <Override>[
          inventoryItemsControllerProvider.overrideWith(
            () => inventoryController,
          ),
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: false,
              enableEatBridge: true,
              enableQueueBackfill: true,
            ),
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
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(inventoryController.discardedPendingIds, <String>['pending-1']);
  });

  testWidgets('failed barcode lookup discards pending consumption', (
    tester,
  ) async {
    final lookupRepository = _RecordingLookupRepository(
      onLookupByBarcode: (_) async =>
          const CalorieLookupOutcome.failed(errorCode: 'failed'),
    );
    final inventoryController = _RecordingInventoryItemsController();
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) {
            return Scaffold(
              body: _EatButton(
                item: _itemWithoutNutrition(barcode: '4006381333931'),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          inventoryItemsControllerProvider.overrideWith(
            () => inventoryController,
          ),
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: false,
              enableEatBridge: true,
              enableQueueBackfill: true,
            ),
          ),
          calorieProductLookupRepositoryProvider.overrideWithValue(
            lookupRepository,
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

    expect(lookupRepository.lookupCalls, 1);
    expect(inventoryController.discardedPendingIds, <String>['pending-1']);
  });

  testWidgets('aborting candidate picker discards pending consumption', (
    tester,
  ) async {
    final lookupRepository = _RecordingLookupRepository(
      onLookupByBarcode: (_) async {
        final now = DateTime(2026, 3, 1, 12);
        return CalorieLookupOutcome.foundMultiple(<CalorieProductCandidate>[
          CalorieProductCandidate(
            profile: CalorieProductProfile(
              barcode: '4006381333931',
              name: 'Milk',
              per100Kcal: 10,
              per100Protein: 1,
              per100Carbs: 2,
              per100Fat: 3,
              source: CalorieProductSource.offSearch,
              createdAt: now,
              updatedAt: now,
            ),
            completenessScore: 10,
          ),
        ]);
      },
    );
    final inventoryController = _RecordingInventoryItemsController();
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) {
            return Scaffold(
              body: _EatButton(
                item: _itemWithoutNutrition(barcode: '4006381333931'),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          inventoryItemsControllerProvider.overrideWith(
            () => inventoryController,
          ),
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: false,
              enableEatBridge: true,
              enableQueueBackfill: true,
            ),
          ),
          calorieProductLookupRepositoryProvider.overrideWithValue(
            lookupRepository,
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

    expect(find.text('Milk'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(inventoryController.discardedPendingIds, <String>['pending-1']);
  });
}
