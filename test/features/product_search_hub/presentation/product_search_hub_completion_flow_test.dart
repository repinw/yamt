import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'eat_sheet/inventory_item_eat_sheet_body.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_pack_choice_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_rest_to_stock_dialog.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_ai_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_completion_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/inventory_item_whole_list_writes.dart';
import '../../calories/support/fake_planned_entry_repository.dart';
import '../support/fake_product_search_sources.dart';

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late _MockUser user;

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
  });

  testWidgets('inventory mode saves result and closes back to the Vorrat', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.inventory(),
            sourceKey: '4006381333931',
            result: _manualResult(),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(completion?.saved, isTrue);
    expect(completion?.shouldCloseHub, isTrue);
    expect(inventoryController.addedItems, hasLength(1));
  });

  testWidgets('a diary food put into the Vorrat closes the hub alone', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            mode: ProductSearchHubMode.inventory,
            sourceKey: '4006381333931',
            result: _manualResult(),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(inventoryController.addedItems, hasLength(1));
    // It does not join the diary selection, and the hub closes.
    expect(completion?.saved, isFalse);
    expect(completion?.shouldCloseHub, isTrue);
    expect(
      find.text('${inventoryController.addedItems.single.name} is in stock'),
      findsOneWidget,
    );
  });

  testWidgets('inventory mode waits for inventory controller before saving', (
    tester,
  ) async {
    final buildGate = Completer<void>();
    final inventoryController = _DelayedBuildInventoryItemsController(
      buildGate,
    );
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.inventory(),
            sourceKey: '4006381333931',
            result: _manualResult(),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(inventoryController.addedItems, isEmpty);
    expect(inventoryController._addCalledBeforeBuild, isFalse);

    buildGate.complete();
    await tester.pumpAndSettle();

    expect(inventoryController._addCalledBeforeBuild, isFalse);
    expect(completion?.saved, isTrue);
    expect(completion?.shouldCloseHub, isTrue);
    expect(inventoryController.addedItems, hasLength(1));
  });

  testWidgets('diary mode rolls saved item back when eat flow fails', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              eatSelection: EatSelection(
                inventoryAmount: 0,
                loggedAt: DateTime.utc(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(completion?.saved, isFalse);
    expect(completion?.shouldCloseHub, isFalse);
    expect(inventoryController.addedItems, hasLength(1));
    expect(
      inventoryController.deletedItemIds,
      contains(inventoryController.addedItems.single.id),
    );
  });

  testWidgets('diary mode waits for inventory controller before saving', (
    tester,
  ) async {
    final buildGate = Completer<void>();
    final inventoryController = _DelayedBuildInventoryItemsController(
      buildGate,
    );
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              eatSelection: EatSelection(
                inventoryAmount: 0,
                loggedAt: DateTime.utc(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(inventoryController.addedItems, isEmpty);
    expect(inventoryController._addCalledBeforeBuild, isFalse);

    buildGate.complete();
    await tester.pumpAndSettle();

    expect(inventoryController._addCalledBeforeBuild, isFalse);
    expect(completion?.saved, isFalse);
    expect(completion?.shouldCloseHub, isFalse);
    expect(inventoryController.addedItems, hasLength(1));
    expect(
      inventoryController.deletedItemIds,
      contains(inventoryController.addedItems.single.id),
    );
  });

  testWidgets(
    'diary mode missing weight opens eat sheet without amount dialog',
    (tester) async {
      final inventoryController = _SuccessfulInventoryItemsController();
      ProductSearchHubCompletionResult? completion;

      await tester.pumpWidget(
        _buildCompletionHarness(
          inventoryController: inventoryController,
          firebaseAuth: firebaseAuth,
          commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
          onRun: (context, container, l10n) async {
            completion = await completeProductSearchHubResult(
              context: context,
              container: container,
              l10n: l10n,
              args: const ProductSearchHubRouteArgs.diary(),
              sourceKey: '4006381333931',
              result: _manualResult(
                item: _manualItemWithNutrition(weight: null),
              ),
            );
          },
        ),
      );

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      expect(completion, isNull);
      expect(
        find.byKey(const Key('inventory_manual_add_eat_amount_field')),
        findsNothing,
      );
      expect(find.byKey(const Key('eat_page_amount_field')), findsOneWidget);
      expect(inventoryController.addedItems, isEmpty);
    },
  );

  testWidgets('diary mode log-only eat closes hub with saved selection', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        firebaseAuth: firebaseAuth,
        commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              item: _manualItemWithNutrition(),
              eatSelection: EatSelection(
                inventoryAmount: 500,
                loggedAt: DateTime.utc(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(completion?.shouldCloseHub, isTrue);
    expect(completion?.saved, isTrue);
    expect(inventoryController.addedItems, hasLength(1));
    expect(inventoryController.stagedConsumptions, hasLength(1));
  });

  testWidgets('diary mode plans a later day and adds nothing to the Vorrat', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();
    final plans = FakePlannedEntryRepository();
    final barcodeRepository = _RecordingGlobalBarcodeCandidateRepository();
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        firebaseAuth: firebaseAuth,
        barcodeRepository: barcodeRepository,
        overrides: [
          plannedEntryRepositoryProvider.overrideWithValue(plans),
          clockProvider.overrideWithValue(() => DateTime(2026, 4, 12, 20)),
          globalFoodItemRepositoryProvider.overrideWithValue(
            FakeGlobalFoodItemRepository(),
          ),
        ],
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              item: _manualItemWithNutrition().copyWith(
                barcode: '4006381333931',
              ),
              eatSelection: EatSelection(
                inventoryAmount: 200,
                loggedAt: DateTime(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
              requiresGlobalPersistence: true,
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(completion?.shouldCloseHub, isTrue);
    expect(completion?.saved, isFalse);
    final plan = plans.plans.single;
    expect(plan.consumedAmount, 200);
    expect(plan.sourceInventoryItemId, isNull);
    expect(plan.sourceInventoryAmountToRestore, isNull);
    expect(inventoryController.addedItems, isEmpty);
    expect(inventoryController.stagedConsumptions, isEmpty);
    // The shared catalog still learns the product.
    expect(barcodeRepository.recordedBarcodes, ['4006381333931']);
    expect(find.text('Planned for the day'), findsOneWidget);
  });

  testWidgets('diary mode plans a later day from the picked Vorrat pack', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();
    final plans = FakePlannedEntryRepository();

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        firebaseAuth: firebaseAuth,
        overrides: [
          plannedEntryRepositoryProvider.overrideWithValue(plans),
          clockProvider.overrideWithValue(() => DateTime(2026, 4, 12, 20)),
          inventoryItemRepositoryProvider.overrideWithValue(
            _StockedInventoryRepository([_stockedPack()]),
          ),
        ],
        onRun: (context, container, l10n) async {
          await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              item: _manualItemWithNutrition(barcode: '4006381333931'),
              eatSelection: EatSelection(
                inventoryAmount: 200,
                loggedAt: DateTime(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(inventoryPackChoiceRowKey('stocked')));
    await tester.pumpAndSettle();

    // The plan keeps the pack, so accepting it takes the stock there.
    final plan = plans.plans.single;
    expect(plan.consumedAmount, 200);
    expect(plan.sourceInventoryItemId, 'stocked');
    expect(plan.sourceInventoryAmountToRestore, 200);
    expect(inventoryController.addedItems, isEmpty);
    expect(find.text('Planned for tomorrow'), findsOneWidget);
  });

  testWidgets('a failed plan says the entry was not saved', (tester) async {
    final inventoryController = _SuccessfulInventoryItemsController();
    final plans = FakePlannedEntryRepository()..writeShouldFail = true;
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        firebaseAuth: firebaseAuth,
        overrides: [
          plannedEntryRepositoryProvider.overrideWithValue(plans),
          clockProvider.overrideWithValue(() => DateTime(2026, 4, 12, 20)),
        ],
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              item: _manualItemWithNutrition(),
              eatSelection: EatSelection(
                inventoryAmount: 200,
                loggedAt: DateTime(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(completion?.shouldCloseHub, isFalse);
    expect(plans.plans, isEmpty);
    expect(inventoryController.addedItems, isEmpty);
    expect(find.text('Could not save entry.'), findsOneWidget);
  });

  testWidgets('diary mode saves the item already sized to the eaten amount', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        firebaseAuth: firebaseAuth,
        commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
        onRun: (context, container, l10n) async {
          await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              item: _manualItemWithNutrition(),
              eatSelection: EatSelection(
                inventoryAmount: 200,
                loggedAt: DateTime.utc(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    // 300 g of the 500 g package stay; "No" keeps only the eaten amount.
    expect(find.text('Put the rest (300 g) into stock?'), findsOneWidget);
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(inventoryController.addedItems.single.currentAmount, 200);
    expect(inventoryController.updatedItems, isEmpty);
    expect(inventoryController.stagedConsumptions.single.amount, 200);
  });

  testWidgets('diary mode keeps the rest of the package in the Vorrat on yes', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        firebaseAuth: firebaseAuth,
        commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
        onRun: (context, container, l10n) async {
          await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              item: _manualItemWithNutrition(),
              eatSelection: EatSelection(
                inventoryAmount: 200,
                loggedAt: DateTime.utc(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(inventoryRestToStockYesKey));
    await tester.pumpAndSettle();

    // The whole package goes into the Vorrat, and 200 g of it are eaten.
    expect(inventoryController.addedItems.single.currentAmount, 500);
    expect(inventoryController.updatedItems, isEmpty);
    expect(inventoryController.stagedConsumptions.single.amount, 200);
  });

  testWidgets('diary mode eats the picked amount from the picked Vorrat pack', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();
    final commitStore = _RecordingCommitStore();

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        firebaseAuth: firebaseAuth,
        commitStore: commitStore,
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            _StockedInventoryRepository([_stockedPack()]),
          ),
        ],
        onRun: (context, container, l10n) async {
          await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              item: _manualItemWithNutrition(barcode: '4006381333931'),
              eatSelection: EatSelection(
                inventoryAmount: 200,
                loggedAt: DateTime.utc(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    expect(find.text('Take from inventory?'), findsOneWidget);
    await tester.tap(find.byKey(inventoryPackChoiceRowKey('stocked')));
    await tester.pumpAndSettle();

    // The amount picked before is eaten from the pack at once: no second
    // eat page, and nothing new goes into the Vorrat.
    expect(find.byType(InventoryItemEatSheetBody), findsNothing);
    final pending = commitStore.pendings.single;
    expect(pending.itemId, 'stocked');
    expect(pending.amount, 200);
    expect(commitStore.entries.single.consumedAmount, 200);
    expect(commitStore.entries.single.sourceInventoryItemId, 'stocked');
    expect(inventoryController.addedItems, isEmpty);
  });

  testWidgets('diary mode without taking stock eats the food as before', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        firebaseAuth: firebaseAuth,
        commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            _StockedInventoryRepository([_stockedPack()]),
          ),
        ],
        onRun: (context, container, l10n) async {
          await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.diary(),
            sourceKey: '4006381333931',
            result: _manualResult(
              item: _manualItemWithNutrition(barcode: '4006381333931'),
              eatSelection: EatSelection(
                inventoryAmount: 200,
                loggedAt: DateTime.utc(2026, 4, 13, 12),
                mealType: MealType.lunch,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(inventoryPackChoiceSkipKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(inventoryController.addedItems.single.currentAmount, 200);
    expect(inventoryController.stagedConsumptions.single.amount, 200);
  });

  testWidgets('selection mode returns no overlay selection and does not save', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: ProductSearchHubRouteArgs.selection(item: _manualItem()),
            sourceKey: '4006381333931',
            result: _manualResult(),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(completion?.saved, isFalse);
    expect(completion?.shouldCloseHub, isFalse);
    expect(inventoryController.addedItems, isEmpty);
    expect(inventoryController.deletedItemIds, isEmpty);
  });

  testWidgets('inventory mode prompts for missing barcode and saves entry', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    final barcodeRepository = _RecordingGlobalBarcodeCandidateRepository();
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        barcodeRepository: barcodeRepository,
        overrides: [
          globalFoodItemRepositoryProvider.overrideWithValue(
            FakeGlobalFoodItemRepository(),
          ),
        ],
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.inventory(),
            sourceKey: 'manual-source',
            result: _manualResult(
              skipMissingBarcodePrompt: false,
              requiresGlobalPersistence: true,
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(find.text('Add barcode?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('inventory_manual_add_missing_barcode_field')),
      ' 4006381333931 ',
    );
    await tester.tap(
      find.byKey(const Key('inventory_manual_add_missing_barcode_save_button')),
    );
    await tester.pumpAndSettle();

    expect(completion?.saved, isTrue);
    expect(completion?.shouldCloseHub, isTrue);
    expect(
      inventoryController.addedItems.single.normalizedBarcode,
      '4006381333931',
    );
    expect(barcodeRepository.recordedBarcodes, ['4006381333931']);
  });

  testWidgets('missing barcode prompt can save without barcode', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    final barcodeRepository = _RecordingGlobalBarcodeCandidateRepository();
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        barcodeRepository: barcodeRepository,
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.inventory(),
            sourceKey: 'manual-source',
            result: _manualResult(skipMissingBarcodePrompt: false),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('inventory_manual_add_missing_barcode_skip_button')),
    );
    await tester.pumpAndSettle();

    expect(completion?.saved, isTrue);
    expect(completion?.shouldCloseHub, isTrue);
    expect(inventoryController.addedItems.single.normalizedBarcode, isNull);
    expect(barcodeRepository.recordedBarcodes, isEmpty);
  });

  group('shared catalog', () {
    Future<FakeGlobalFoodItemRepository> save(
      WidgetTester tester,
      InventoryReceiptManualProductResult result, {
      List<InventoryItem>? savedItems,
    }) async {
      final inventoryController = _RecordingInventoryItemsController();
      final catalog = FakeGlobalFoodItemRepository();
      await tester.pumpWidget(
        _buildCompletionHarness(
          inventoryController: inventoryController,
          overrides: [
            globalFoodItemRepositoryProvider.overrideWithValue(catalog),
          ],
          onRun: (context, container, l10n) async {
            await completeProductSearchHubResult(
              context: context,
              container: container,
              l10n: l10n,
              args: const ProductSearchHubRouteArgs.inventory(),
              sourceKey: 'manual-source',
              result: result,
            );
          },
        ),
      );

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      expect(inventoryController.addedItems, hasLength(1));
      savedItems?.addAll(inventoryController.addedItems);
      return catalog;
    }

    testWidgets('learns an own product', (tester) async {
      final catalog = await save(
        tester,
        InventoryReceiptManualProductResult(
          item: _manualItemWithNutrition(),
          action: InventoryReceiptManualProductAction.addToInventory,
          skipMissingBarcodePrompt: true,
        ),
      );

      expect(catalog.appendedItems.single.name, 'Muesli');
    });

    testWidgets('does not learn an AI food, the meal of one user (#655)', (
      tester,
    ) async {
      final catalog = await save(
        tester,
        productSearchHubAiResult(
          ManualProductAiSearchResult(
            item: _manualItemWithNutrition(),
            action: InventoryReceiptManualProductAction.addToInventory,
            globalPackageWeight: '500 g',
          ),
        ),
      );

      expect(catalog.appendedItems, isEmpty);
    });

    testWidgets('keeps the AI estimate on the saved item, and only on an '
        'AI food (#763)', (tester) async {
      const estimate = SavedFoodEstimate(
        estimate: FoodEstimate(
          name: 'Muesli',
          portionGrams: 80,
          kcalLean: 280,
          kcalRich: 340,
          per100: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
            per100Kcal: 380,
          ),
          ingredients: [
            FoodEstimateIngredient(name: 'Hafer', grams: 60, kcal: 220),
          ],
        ),
        level: FoodEstimateLevel.lean,
        description: 'Muesli mit Milch',
      );
      final item = _manualItemWithNutrition();
      final withEstimate = item.copyWith(
        productSnapshot: item.productSnapshot.copyWith(aiEstimate: estimate),
      );
      final aiItems = <InventoryItem>[];
      final realItems = <InventoryItem>[];

      await save(
        tester,
        productSearchHubAiResult(
          ManualProductAiSearchResult(
            item: withEstimate.copyWith(aiEstimated: true),
            action: InventoryReceiptManualProductAction.addToInventory,
            globalPackageWeight: '500 g',
          ),
        ),
        savedItems: aiItems,
      );
      // A real product picked for it: the estimate described the old food.
      await save(
        tester,
        InventoryReceiptManualProductResult(
          item: withEstimate,
          action: InventoryReceiptManualProductAction.addToInventory,
          skipMissingBarcodePrompt: true,
        ),
        savedItems: realItems,
      );

      expect(aiItems.single.productSnapshot.aiEstimate, estimate);
      expect(realItems.single.productSnapshot.aiEstimate, isNull);
    });

    testWidgets('keeps an AI food private when another path rebuilt its '
        'result, and keeps the mark on the saved item (#701)', (tester) async {
      final savedItems = <InventoryItem>[];
      // Like the editor after "Bearbeiten" or a reopen: no AI flag on the
      // result, which asks for the catalog by default.
      final catalog = await save(
        tester,
        InventoryReceiptManualProductResult(
          item: _manualItemWithNutrition().copyWith(aiEstimated: true),
          action: InventoryReceiptManualProductAction.addToInventory,
          skipMissingBarcodePrompt: true,
        ),
        savedItems: savedItems,
      );

      expect(catalog.appendedItems, isEmpty);
      expect(savedItems.single.aiEstimated, isTrue);
    });
  });

  group('barcode candidate', () {
    late _ControllerBackedInventoryRepository inventoryRepository;

    Future<(List<InventoryItem>, List<String>)> save(
      WidgetTester tester,
      InventoryReceiptManualProductResult result, {
      bool catalogWriteSucceeds = true,
    }) async {
      final inventoryController = _RecordingInventoryItemsController();
      final barcodeRepository = _RecordingGlobalBarcodeCandidateRepository();
      inventoryRepository = _ControllerBackedInventoryRepository(
        inventoryController,
      );
      await tester.pumpWidget(
        _buildCompletionHarness(
          inventoryController: inventoryController,
          barcodeRepository: barcodeRepository,
          overrides: [
            globalFoodItemRepositoryProvider.overrideWithValue(
              catalogWriteSucceeds
                  ? FakeGlobalFoodItemRepository()
                  : _FailingGlobalFoodItemRepository(),
            ),
            inventoryItemRepositoryProvider.overrideWithValue(
              inventoryRepository,
            ),
          ],
          onRun: (context, container, l10n) async {
            await completeProductSearchHubResult(
              context: context,
              container: container,
              l10n: l10n,
              args: const ProductSearchHubRouteArgs.inventory(),
              sourceKey: 'manual-source',
              result: result,
            );
          },
        ),
      );

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      return (
        inventoryController.addedItems,
        barcodeRepository.recordedBarcodes,
      );
    }

    testWidgets('a product outside the catalog gets none and a pending id '
        '(#698)', (tester) async {
      final (items, barcodes) = await save(
        tester,
        _manualResult(item: _manualItem().copyWith(barcode: '4006381333931')),
      );

      expect(barcodes, isEmpty);
      expect(isPendingGlobalFoodItemId(items.single.globalFoodItemId), isTrue);
    });

    testWidgets('a picked catalog product keeps its id and its barcode', (
      tester,
    ) async {
      final (items, barcodes) = await save(
        tester,
        InventoryReceiptManualProductResult(
          item: _manualItem().copyWith(barcode: '4006381333931'),
          action: InventoryReceiptManualProductAction.addToInventory,
          requiresGlobalPersistence: false,
          skipMissingBarcodePrompt: true,
          selectedGlobalFoodItemId: 'catalog-muesli',
        ),
      );

      expect(barcodes, ['4006381333931']);
      expect(items.single.globalFoodItemId, 'catalog-muesli');
    });

    testWidgets('a new product gets its catalog id and records its barcode '
        'once the catalog has it (#806)', (tester) async {
      final (items, barcodes) = await save(
        tester,
        _manualResult(
          item: _manualItem().copyWith(barcode: '4006381333931'),
          requiresGlobalPersistence: true,
        ),
      );

      expect(barcodes, ['4006381333931']);
      expect(isPendingGlobalFoodItemId(items.single.globalFoodItemId), isTrue);
      final linked = inventoryRepository.savedItems.single;
      expect(linked.id, items.single.id);
      expect(isPendingGlobalFoodItemId(linked.globalFoodItemId), isFalse);
    });

    testWidgets('a new product stays private when the catalog write fails '
        '(#806)', (tester) async {
      final (items, barcodes) = await save(
        tester,
        _manualResult(
          item: _manualItem().copyWith(barcode: '4006381333931'),
          requiresGlobalPersistence: true,
        ),
        catalogWriteSucceeds: false,
      );

      expect(barcodes, isEmpty);
      expect(isPendingGlobalFoodItemId(items.single.globalFoodItemId), isTrue);
      expect(inventoryRepository.savedItems, isEmpty);
    });
  });

  testWidgets('missing barcode prompt cancel does not save', (tester) async {
    final inventoryController = _RecordingInventoryItemsController();
    ProductSearchHubCompletionResult? completion;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          completion = await completeProductSearchHubResult(
            context: context,
            container: container,
            l10n: l10n,
            args: const ProductSearchHubRouteArgs.inventory(),
            sourceKey: 'manual-source',
            result: _manualResult(skipMissingBarcodePrompt: false),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('inventory_manual_add_missing_barcode_cancel_button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(completion?.saved, isFalse);
    expect(completion?.shouldCloseHub, isFalse);
    expect(inventoryController.addedItems, isEmpty);
  });
}

Widget _buildCompletionHarness({
  required _RecordingInventoryItemsController inventoryController,
  required Future<void> Function(
    BuildContext context,
    ProviderContainer container,
    AppLocalizations l10n,
  )
  onRun,
  GlobalBarcodeCandidateRepository barcodeRepository =
      const _NoopGlobalBarcodeCandidateRepository(),
  FirebaseAuth? firebaseAuth,
  InventoryCalorieEntryCommitStore? commitStore,
  List<Override> overrides = const <Override>[],
}) {
  final container = ProviderContainer(
    overrides: [
      firebaseAuthProvider.overrideWithValue(
        firebaseAuth ?? _MockFirebaseAuth(),
      ),
      inventoryItemsControllerProvider.overrideWith(() => inventoryController),
      globalBarcodeCandidateRepositoryProvider.overrideWithValue(
        barcodeRepository,
      ),
      if (commitStore != null)
        inventoryCalorieEntryCommitStoreProvider.overrideWithValue(commitStore),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
                final l10n = AppLocalizations.of(context)!;
                unawaited(onRun(context, container, l10n));
              },
              child: const Text('run'),
            );
          },
        ),
      ),
    ),
  );
}

class _RecordingInventoryItemsController extends InventoryItemsController {
  final addedItems = <InventoryItem>[];
  final updatedItems = <InventoryItem>[];
  final deletedItemIds = <String>[];

  @override
  Future<List<InventoryItem>> build() async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> addItem(InventoryItem item) async {
    addedItems.add(item);
    return true;
  }

  @override
  Future<bool> updateItem(InventoryItem item) async {
    updatedItems.add(item);
    return true;
  }

  @override
  Future<bool> deleteItem(String itemId) async {
    deletedItemIds.add(itemId);
    return true;
  }

  @override
  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) async {
    return null;
  }
}

/// Reads the Vorrat that [_controller] added and records single writes.
class _ControllerBackedInventoryRepository with InventoryItemWholeListWrites {
  new(this._controller);

  final _RecordingInventoryItemsController _controller;

  /// The items written one by one after the save.
  final savedItems = <InventoryItem>[];

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield _controller.addedItems;
  }

  @override
  Future<List<InventoryItem>> readAll() async => _controller.addedItems;

  @override
  Future<bool> save(InventoryItem item) async {
    savedItems.add(item);
    return true;
  }

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

class _FailingGlobalFoodItemRepository extends FakeGlobalFoodItemRepository {
  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async => false;
}

class _DelayedBuildInventoryItemsController
    extends _RecordingInventoryItemsController {
  new(this._buildGate);

  final Completer<void> _buildGate;
  var _didBuild = false;
  var _addCalledBeforeBuild = false;

  @override
  Future<List<InventoryItem>> build() async {
    await _buildGate.future;
    _didBuild = true;
    return const <InventoryItem>[];
  }

  @override
  Future<bool> addItem(InventoryItem item) async {
    if (!_didBuild) {
      _addCalledBeforeBuild = true;
      return false;
    }
    return await super.addItem(item);
  }
}

class _SuccessfulInventoryItemsController
    extends _RecordingInventoryItemsController {
  final stagedConsumptions = <PendingInventoryConsumption>[];

  @override
  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) async {
    final pendingConsumption = PendingInventoryConsumption(
      id: 'pending-$itemId',
      itemId: itemId,
      amount: amount,
    );
    stagedConsumptions.add(pendingConsumption);
    return pendingConsumption;
  }
}

class _SuccessfulInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  const new();

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) async {
    return [
      InventoryCalorieEntryCommitResult(
        itemId: pendingConsumptions.single.itemId,
        quantity: 1,
        currentAmount: 400,
      ),
    ];
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async => null;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) => throw UnimplementedError();
}

/// Records the entries and stock that go out together.
class _RecordingCommitStore
    extends _SuccessfulInventoryCalorieEntryCommitStore {
  final entries = <CalorieEntry>[];
  final pendings = <PendingInventoryConsumption>[];

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) {
    entries.add(entry);
    pendings.addAll(pendingConsumptions);
    return super.commitEntryAndInventoryItems(
      entry: entry,
      pendingConsumptions: pendingConsumptions,
    );
  }
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

class _RecordingGlobalBarcodeCandidateRepository
    implements GlobalBarcodeCandidateRepository {
  final recordedBarcodes = <String>[];

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async {
    return const <GlobalBarcodeCandidate>[];
  }

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {
    recordedBarcodes.add(barcode);
  }
}

class _NoopGlobalBarcodeCandidateRepository
    implements GlobalBarcodeCandidateRepository {
  const new();

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async {
    return const <GlobalBarcodeCandidate>[];
  }

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {}
}

InventoryReceiptManualProductResult _manualResult({
  InventoryItem? item,
  EatSelection? eatSelection,
  bool skipMissingBarcodePrompt = true,
  bool requiresGlobalPersistence = false,
}) {
  return InventoryReceiptManualProductResult(
    item: item ?? _manualItem(),
    action: eatSelection == null
        ? InventoryReceiptManualProductAction.addToInventory
        : InventoryReceiptManualProductAction.eatNow,
    requiresGlobalPersistence: requiresGlobalPersistence,
    skipMissingBarcodePrompt: skipMissingBarcodePrompt,
    eatSelection: eatSelection,
  );
}

InventoryItem _manualItem() {
  return InventoryItem.create(
    id: 'manual-item',
    name: 'Muesli',
    entryDate: DateTime.utc(2026, 4, 13),
    storeName: 'Manual',
    quantity: 1,
    weight: '500 g',
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _manualItemWithNutrition({
  String? weight = '500 g',
  String? barcode,
}) {
  return InventoryItem.create(
    id: 'manual-item',
    name: 'Muesli',
    brand: 'Grain Co',
    barcode: barcode,
    entryDate: DateTime.utc(2026, 4, 13),
    storeName: 'Manual',
    quantity: 1,
    weight: weight,
    initialAmount: weight == null ? 0 : 500,
    currentAmount: weight == null ? 0 : 500,
    amountUnit: weight == null ? null : InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 360,
      per100Protein: 10,
      per100Carbs: 60,
      per100Fat: 6,
    ),
  );
}

/// An opened pack of the Muesli with the barcode 4006381333931.
InventoryItem _stockedPack() =>
    _manualItemWithNutrition(barcode: '4006381333931')
        .copyWith(id: 'stocked', currentAmount: 300);

/// A Vorrat that holds [_items].
class _StockedInventoryRepository with InventoryItemWholeListWrites {
  new(this._items);

  final List<InventoryItem> _items;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield _items;
  }

  @override
  Future<List<InventoryItem>> readAll() async => _items;

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}
