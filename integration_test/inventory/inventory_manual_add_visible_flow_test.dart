import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_page.dart';
import 'package:yamt/features/product_search/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _RecordingInventoryItemRepository implements InventoryItemRepository {
  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  final List<InventoryItem> appendedItems = <InventoryItem>[];
  final List<InventoryItem> _items = <InventoryItem>[];

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    _items.addAll(items);
    appendedItems.addAll(items);
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    _items
      ..clear()
      ..addAll(items);
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.multi((controller) {
      controller.add(List<InventoryItem>.from(_items));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  Future<void> dispose() {
    return _controller.close();
  }
}

class _RecordingGlobalFoodItemRepository implements GlobalFoodItemRepository {
  final List<GlobalFoodItem> appendedItems = <GlobalFoodItem>[];

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async {
    appendedItems.addAll(items);
    return true;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async {
    return const <GlobalFoodItem>[];
  }

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async {
    return true;
  }

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    return const <GlobalFoodItem>[];
  }

  @override
  Stream<List<GlobalFoodItem>> watchAll() {
    return const Stream<List<GlobalFoodItem>>.empty();
  }
}

class _RecordingGlobalBarcodeCandidateRepository
    implements GlobalBarcodeCandidateRepository {
  final List<({String barcode, GlobalFoodItem globalFoodItem})>
  recordedSelections = <({String barcode, GlobalFoodItem globalFoodItem})>[];

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
    recordedSelections.add((barcode: barcode, globalFoodItem: globalFoodItem));
  }
}

class _RecordingOffProductSearchRepository
    implements OffProductSearchRepository {
  _RecordingOffProductSearchRepository(this.results);

  final List<OffProductSearchResult> results;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    return results;
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return results;
  }
}

class _IntegrationInventoryItemsController extends InventoryItemsController {
  _IntegrationInventoryItemsController(this.repository);

  final InventoryItemRepository repository;

  @override
  Future<List<InventoryItem>> build() {
    return repository.readAll();
  }

  @override
  Future<bool> addItem(InventoryItem item) async {
    return repository.appendAll(<InventoryItem>[item]);
  }
}

class _ManualAddIntegrationHarness {
  const _ManualAddIntegrationHarness({
    required this.app,
    required this.inventoryRepository,
    required this.globalFoodRepository,
    required this.barcodeCandidateRepository,
  });

  final Widget app;
  final _RecordingInventoryItemRepository inventoryRepository;
  final _RecordingGlobalFoodItemRepository globalFoodRepository;
  final _RecordingGlobalBarcodeCandidateRepository barcodeCandidateRepository;
}

@Dependencies([
  inventoryItemRepository,
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
])
_ManualAddIntegrationHarness _buildHarness() {
  final inventoryRepository = _RecordingInventoryItemRepository();
  final globalFoodRepository = _RecordingGlobalFoodItemRepository();
  final barcodeCandidateRepository =
      _RecordingGlobalBarcodeCandidateRepository();
  final offRepository = _RecordingOffProductSearchRepository(
    <OffProductSearchResult>[
      const OffProductSearchResult(
        code: '4006381333931',
        name: 'Milk',
        brand: 'Brand',
        score: 99,
        packageWeight: '1 l',
        imageUrl: 'https://example.com/milk.png',
        nutrition: GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 100,
          per100Fat: 3,
          per100SaturatedFat: 2,
          per100Carbs: 20,
          per100Sugar: 20,
          per100Protein: 10,
          per100Salt: 0.1,
        ),
      ),
    ],
  );

  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryManualAdd,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.homeInventoryManualAdd,
        builder: (context, state) => const InventoryManualAddPage(),
      ),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        pageBuilder: (context, state) {
          final args = state.extra! as ManualProductSearchRouteArgs;
          return NoTransitionPage<Object?>(
            key: state.pageKey,
            child: args.builder(context),
          );
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(inventoryRepository.dispose);

  final container = ProviderContainer(
    overrides: [
      offProductSearchRepositoryProvider.overrideWithValue(offRepository),
      inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
      globalFoodItemRepositoryProvider.overrideWithValue(globalFoodRepository),
      globalBarcodeCandidateRepositoryProvider.overrideWithValue(
        barcodeCandidateRepository,
      ),
      inventoryItemsControllerProvider.overrideWith(
        () => _IntegrationInventoryItemsController(inventoryRepository),
      ),
    ],
  );
  addTearDown(container.dispose);

  return _ManualAddIntegrationHarness(
    app: UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
    inventoryRepository: inventoryRepository,
    globalFoodRepository: globalFoodRepository,
    barcodeCandidateRepository: barcodeCandidateRepository,
  );
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _showStep(
  WidgetTester tester, {
  Duration observeFor = const Duration(seconds: 1),
}) async {
  await _pumpUi(tester);
  await Future<void>.delayed(observeFor);
  await tester.pump();
}

@Dependencies([
  inventoryItemRepository,
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('manual add flow runs visibly on Android', (tester) async {
    final harness = _buildHarness();

    await tester.pumpWidget(harness.app);
    await _showStep(tester, observeFor: const Duration(seconds: 2));

    final launcherSearchField = find.byKey(
      const Key('receipt_review_manual_launcher_search_field'),
    );
    expect(launcherSearchField, findsOneWidget);

    await tester.tap(launcherSearchField);
    await _showStep(tester);

    final searchField = find.byKey(
      const Key('receipt_review_manual_search_field'),
    );
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Milk');
    await _showStep(tester);

    final resultTile = find.byKey(
      const Key(
        'receipt_review_manual_search_result_store_button_4006381333931',
      ),
    );
    expect(resultTile, findsOneWidget);

    await tester.tap(resultTile);
    await _showStep(tester);

    final saveButton = find.byKey(
      const Key('receipt_review_manual_save_button'),
    );
    expect(saveButton, findsOneWidget);

    await tester.ensureVisible(saveButton);
    await _pumpUi(tester);
    await tester.tap(saveButton);
    await _showStep(tester, observeFor: const Duration(seconds: 2));

    expect(harness.inventoryRepository.appendedItems, hasLength(1));
    expect(harness.inventoryRepository.appendedItems.single.name, 'Milk');
    expect(harness.globalFoodRepository.appendedItems, hasLength(1));
    expect(harness.barcodeCandidateRepository.recordedSelections, hasLength(1));
    expect(launcherSearchField, findsNothing);
    expect(searchField, findsOneWidget);
  });
}
