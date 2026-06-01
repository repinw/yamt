import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
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
  testWidgets('inventory mode saves result and returns overlay selection', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    ProductSearchHubSavedSelection? selection;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          selection = await completeProductSearchHubResult(
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

    expect(selection, isNotNull);
    expect(selection!.sourceKey, '4006381333931');
    expect(inventoryController.addedItems, hasLength(1));
    expect(selection!.item.id, inventoryController.addedItems.single.id);
  });

  testWidgets('diary mode rolls saved item back when eat flow fails', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    ProductSearchHubSavedSelection? selection;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          selection = await completeProductSearchHubResult(
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

    expect(selection, isNull);
    expect(inventoryController.addedItems, hasLength(1));
    expect(
      inventoryController.deletedItemIds,
      contains(inventoryController.addedItems.single.id),
    );
  });

  testWidgets('selection mode returns no overlay selection and does not save', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    ProductSearchHubSavedSelection? selection;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          selection = await completeProductSearchHubResult(
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

    expect(selection, isNull);
    expect(inventoryController.addedItems, isEmpty);
    expect(inventoryController.deletedItemIds, isEmpty);
  });

  testWidgets('inventory mode prompts for missing barcode and saves entry', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    final barcodeRepository = _RecordingGlobalBarcodeCandidateRepository();
    ProductSearchHubSavedSelection? selection;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        barcodeRepository: barcodeRepository,
        onRun: (context, container, l10n) async {
          selection = await completeProductSearchHubResult(
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

    expect(selection, isNotNull);
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
    ProductSearchHubSavedSelection? selection;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        barcodeRepository: barcodeRepository,
        onRun: (context, container, l10n) async {
          selection = await completeProductSearchHubResult(
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

    expect(selection, isNotNull);
    expect(inventoryController.addedItems.single.normalizedBarcode, isNull);
    expect(barcodeRepository.recordedBarcodes, isEmpty);
  });

  testWidgets('missing barcode prompt cancel does not save', (tester) async {
    final inventoryController = _RecordingInventoryItemsController();
    ProductSearchHubSavedSelection? selection;

    await tester.pumpWidget(
      _buildCompletionHarness(
        inventoryController: inventoryController,
        onRun: (context, container, l10n) async {
          selection = await completeProductSearchHubResult(
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

    expect(selection, isNull);
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
}) {
  final container = ProviderContainer(
    overrides: [
      inventoryItemsControllerProvider.overrideWith(
        () => inventoryController,
      ),
      globalBarcodeCandidateRepositoryProvider.overrideWithValue(
        barcodeRepository,
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
  EatSelection? eatSelection,
  bool skipMissingBarcodePrompt = true,
}) {
  return InventoryReceiptManualProductResult(
    item: _manualItem(),
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
