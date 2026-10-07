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
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_product_search_hub_completion_handler.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_eat_coordinator.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_product_search_hub_completion_handler.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_rest_to_stock_dialog.dart';
import 'package:yamt/features/product_search_hub/application/product_search_hub_completion_providers.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_completion_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_planned_entry_repository.dart';

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

    final selection = completion?.selection;
    expect(selection, isNotNull);
    if (selection == null) {
      fail('Expected saved selection.');
    }
    expect(completion?.shouldCloseHub, isTrue);
    expect(selection.sourceKey, '4006381333931');
    expect(inventoryController.addedItems, hasLength(1));
    expect(selection.item.id, inventoryController.addedItems.single.id);
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
    expect(completion?.selection, isNull);
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
    expect(completion?.selection, isNotNull);
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

    expect(completion?.selection, isNull);
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
    expect(completion?.selection, isNull);
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
    final selection = completion?.selection;
    expect(selection, isNotNull);
    if (selection == null) {
      fail('Expected saved selection.');
    }
    expect(selection.sourceKey, '4006381333931');
    expect(selection.calorieEntryId, isNotNull);
    expect(selection.calorieEntryId, isNotEmpty);
    expect(inventoryController.addedItems, hasLength(1));
    expect(selection.item.id, inventoryController.addedItems.single.id);
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
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(completion?.shouldCloseHub, isTrue);
    expect(completion?.selection, isNull);
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

  test(
    'removing diary selection deletes diary entry and inventory item',
    () async {
      final inventoryController = _RecordingInventoryItemsController();
      final calorieRepository = _RecordingCalorieLogRepository();
      final container = ProviderContainer(
        overrides: [
          inventoryItemsControllerProvider.overrideWith(
            () => inventoryController,
          ),
          productSearchHubCompletionHandlerFactoryProvider.overrideWith((ref) {
            return (_) => DiaryProductSearchHubCompletionHandler(
              container: ref.container,
              eatCoordinator: ref.container.read(
                inventoryManualProductEatCoordinatorProvider,
              ),
            );
          }),
          calorieLogRepositoryProvider.overrideWithValue(calorieRepository),
        ],
      );
      addTearDown(container.dispose);

      final deleted = await removeProductSearchHubSelection(
        container: container,
        selection: ProductSearchHubSavedSelection(
          item: _manualItem(),
          sourceKey: '4006381333931',
          calorieEntryId: 'entry-1',
        ),
      );

      expect(deleted, isTrue);
      expect(calorieRepository.deletedEntryIds, ['entry-1']);
      expect(inventoryController.deletedItemIds, ['manual-item']);
    },
  );

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

    expect(completion?.selection, isNull);
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

    expect(find.text('Add barcode?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('inventory_manual_add_missing_barcode_field')),
      ' 4006381333931 ',
    );
    await tester.tap(
      find.byKey(const Key('inventory_manual_add_missing_barcode_save_button')),
    );
    await tester.pumpAndSettle();

    expect(completion?.selection, isNotNull);
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

    expect(completion?.selection, isNotNull);
    expect(completion?.shouldCloseHub, isTrue);
    expect(inventoryController.addedItems.single.normalizedBarcode, isNull);
    expect(barcodeRepository.recordedBarcodes, isEmpty);
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

    expect(completion?.selection, isNull);
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
      productSearchHubCompletionHandlerFactoryProvider.overrideWith((ref) {
        final container = ref.container;
        return (mode) => switch (mode) {
          ProductSearchHubMode.inventory =>
            InventoryProductSearchHubCompletionHandler(container: container),
          ProductSearchHubMode.diary => DiaryProductSearchHubCompletionHandler(
            container: container,
            eatCoordinator: container.read(
              inventoryManualProductEatCoordinatorProvider,
            ),
          ),
          ProductSearchHubMode.selection || ProductSearchHubMode.mealFood =>
            const SelectionProductSearchHubCompletionHandler(),
        };
      }),
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

class _RecordingCalorieLogRepository implements CalorieLogRepositoryContract {
  final deletedEntryIds = <String>[];

  @override
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    return Stream<List<CalorieEntry>>.value(const <CalorieEntry>[]);
  }

  @override
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day) async {
    return const <CalorieEntry>[];
  }

  @override
  Future<List<CalorieEntry>> readEntriesInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    return const <CalorieEntry>[];
  }

  @override
  Future<DateTime?> readFirstEntryDate() async {
    return null;
  }

  @override
  Future<bool> saveEntry(CalorieEntry entry) async {
    return false;
  }

  @override
  Future<bool> saveEntryForCurrentUser(CalorieEntry entry) async {
    return false;
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    deletedEntryIds.add(entryId);
    return true;
  }

  @override
  CalorieEntry? cachedById(String entryId) => null;

  @override
  Future<CalorieEntry?> getById(String entryId) async {
    return null;
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
}) {
  return InventoryReceiptManualProductResult(
    item: item ?? _manualItem(),
    action: eatSelection == null
        ? InventoryReceiptManualProductAction.addToInventory
        : InventoryReceiptManualProductAction.eatNow,
    requiresGlobalPersistence: false,
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

InventoryItem _manualItemWithNutrition({String? weight = '500 g'}) {
  return InventoryItem.create(
    id: 'manual-item',
    name: 'Muesli',
    brand: 'Grain Co',
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
