import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'models/product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_completion_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
void main() {
  late _MockFirebaseAuth firebaseAuth;
  late _MockUser user;

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
  });

  testWidgets('inventory mode saves result and returns overlay selection', (
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
    expect(completion?.shouldCloseHub, isFalse);
    expect(selection.sourceKey, '4006381333931');
    expect(inventoryController.addedItems, hasLength(1));
    expect(selection.item.id, inventoryController.addedItems.single.id);
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
    expect(completion?.shouldCloseHub, isFalse);
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
    (
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
      expect(
        find.byKey(const Key('inventory_item_amount_dialog_field')),
        findsOneWidget,
      );
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
    expect(inventoryController.finalizedDraftIds, hasLength(1));
    expect(
      inventoryController.finalizedDraftIds.single,
      inventoryController.stagedConsumptions.single.id,
    );
  });

  testWidgets('diary mode add-more eat returns overlay selection', (
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
            result: _manualResult(item: _manualItemWithNutrition()),
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    final addMoreButton = find.byKey(
      const Key('inventory_item_amount_dialog_add_more_button'),
    );
    await tester.ensureVisible(addMoreButton);
    await tester.tap(addMoreButton);
    await tester.pumpAndSettle();
    await _pumpUntil(tester, () => completion != null);

    expect(completion, isNotNull);
    expect(completion?.shouldCloseHub, isFalse);
    final selection = completion?.selection;
    expect(selection, isNotNull);
    if (selection == null) {
      fail('Expected saved selection.');
    }
    expect(selection.sourceKey, '4006381333931');
    expect(inventoryController.addedItems, hasLength(1));
    expect(inventoryController.stagedConsumptions, hasLength(1));
    expect(inventoryController.finalizedDraftIds, hasLength(1));
    expect(
      inventoryController.finalizedDraftIds.single,
      inventoryController.stagedConsumptions.single.id,
    );
    expect(selection.item.id, inventoryController.addedItems.single.id);
    expect(selection.calorieEntryId, isNotNull);
    expect(selection.calorieEntryId, isNotEmpty);
  });

  test(
    'removing diary selection deletes diary entry and inventory item',
    () async {
      final inventoryController = _RecordingInventoryItemsController();
      final calorieEntriesController = _RecordingCalorieEntriesController();
      final container = ProviderContainer(
        overrides: [
          inventoryItemsControllerProvider.overrideWith(
            () => inventoryController,
          ),
          calorieEntriesControllerProvider.overrideWith(
            () => calorieEntriesController,
          ),
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
      expect(calorieEntriesController.deletedEntryIds, ['entry-1']);
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
    expect(completion?.shouldCloseHub, isFalse);
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
    expect(completion?.shouldCloseHub, isFalse);
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
}) {
  final container = ProviderContainer(
    overrides: [
      if (firebaseAuth != null)
        firebaseAuthProvider.overrideWithValue(firebaseAuth),
      inventoryItemsControllerProvider.overrideWith(
        () => inventoryController,
      ),
      globalBarcodeCandidateRepositoryProvider.overrideWithValue(
        barcodeRepository,
      ),
      if (commitStore != null)
        inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
          commitStore,
        ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var attempts = 0; attempts < 20 && !condition(); attempts++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _DelayedBuildInventoryItemsController
    extends _RecordingInventoryItemsController {
  _DelayedBuildInventoryItemsController(this._buildGate);

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
    return super.addItem(item);
  }
}

class _SuccessfulInventoryItemsController
    extends _RecordingInventoryItemsController {
  final stagedConsumptions = <PendingInventoryConsumption>[];
  final finalizedDraftIds = <String>[];

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

  @override
  Future<bool> finalizeCommittedPendingConsumption({
    required String draftId,
    required String itemId,
    required int quantity,
    required int currentAmount,
    DateTime? consumedAt,
  }) async {
    finalizedDraftIds.add(draftId);
    return true;
  }
}

class _RecordingCalorieEntriesController extends CalorieEntriesController {
  final deletedEntryIds = <String>[];

  @override
  Future<List<CalorieEntry>> build() async {
    return const <CalorieEntry>[];
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    deletedEntryIds.add(entryId);
    return true;
  }
}

class _SuccessfulInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  const _SuccessfulInventoryCalorieEntryCommitStore();

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    return InventoryCalorieEntryCommitResult(
      itemId: pendingConsumption.itemId,
      quantity: 1,
      currentAmount: 400,
    );
  }
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

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
  const _NoopGlobalBarcodeCandidateRepository();

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
