import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_page.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

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

class _FailingInventoryItemRepository
    extends _RecordingInventoryItemRepository {
  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return false;
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
  _RecordingGlobalBarcodeCandidateRepository({
    this.candidates = const <GlobalBarcodeCandidate>[],
  });

  final List<GlobalBarcodeCandidate> candidates;
  final List<({String barcode, GlobalFoodItem globalFoodItem})>
  recordedSelections = <({String barcode, GlobalFoodItem globalFoodItem})>[];

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async {
    return candidates;
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

class _RecordingInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  PendingInventoryConsumption? pendingConsumption;

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    this.pendingConsumption = pendingConsumption;
    return InventoryCalorieEntryCommitResult(
      itemId: pendingConsumption.itemId,
      quantity: 1,
      currentAmount: 999,
    );
  }
}

class _FailingStageInventoryItemsController extends InventoryItemsController {
  @override
  Future<List<InventoryItem>> build() async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> addItem(InventoryItem item) async {
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

class _RecordingOffProductSearchRepository
    implements OffProductSearchRepository {
  _RecordingOffProductSearchRepository(this.results);

  final List<OffProductSearchResult> results;
  String? lastBarcode;

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
    lastBarcode = barcode;
    return results;
  }
}

class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  final StreamController<BarcodeCapture?> _barcodeController =
      StreamController<BarcodeCapture?>.broadcast();
  final StreamController<TorchState> _torchController =
      StreamController<TorchState>.broadcast();
  final StreamController<double> _zoomController =
      StreamController<double>.broadcast();

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodeController.stream;

  @override
  Stream<TorchState> get torchStateStream => _torchController.stream;

  @override
  Stream<double> get zoomScaleStateStream => _zoomController.stream;

  @override
  Widget buildCameraView() {
    return const SizedBox.expand();
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<Set<CameraLensType>> getSupportedLenses() async {
    return <CameraLensType>{CameraLensType.any};
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  Future<void> setFocusPoint(Offset position) async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(1080, 1920),
      initialDeviceOrientation: DeviceOrientation.portraitUp,
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  void emitBarcode(String rawValue) {
    _barcodeController.add(
      BarcodeCapture(barcodes: <Barcode>[Barcode(rawValue: rawValue)]),
    );
  }

  Future<void> shutdown() async {
    await _barcodeController.close();
    await _torchController.close();
    await _zoomController.close();
  }
}

Widget _buildHarness({
  required OffProductSearchRepository offRepository,
  required InventoryItemRepository inventoryRepository,
  required GlobalFoodItemRepository globalFoodRepository,
  GlobalBarcodeCandidateRepository? barcodeCandidateRepository,
  FirebaseAuth? auth,
  FakeCalorieLogRepository? calorieLogRepository,
  FakeCalorieProductCacheRepository? calorieProductCacheRepository,
  InventoryCalorieEntryCommitStore? inventoryCommitStore,
  InventoryItemsController Function()? inventoryItemsControllerFactory,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.root,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const _TestHomePage(),
      ),
      GoRoute(
        path: AppRoutes.homeInventoryManualAdd,
        builder: (context, state) => const InventoryManualAddPage(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      offProductSearchRepositoryProvider.overrideWithValue(offRepository),
      inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
      globalFoodItemRepositoryProvider.overrideWithValue(globalFoodRepository),
      if (barcodeCandidateRepository != null)
        globalBarcodeCandidateRepositoryProvider.overrideWithValue(
          barcodeCandidateRepository,
        ),
      if (auth != null) firebaseAuthProvider.overrideWithValue(auth),
      if (calorieLogRepository != null)
        calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      if (calorieProductCacheRepository != null)
        calorieProductCacheRepositoryProvider.overrideWithValue(
          calorieProductCacheRepository,
        ),
      if (inventoryCommitStore != null)
        inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
          inventoryCommitStore,
        ),
      if (inventoryItemsControllerFactory != null)
        inventoryItemsControllerProvider.overrideWith(
          inventoryItemsControllerFactory,
        ),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

class _TestHomePage extends StatefulWidget {
  const _TestHomePage();

  @override
  State<_TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<_TestHomePage> {
  bool _hasOpenedManualAdd = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasOpenedManualAdd) {
      return;
    }
    _hasOpenedManualAdd = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.push(AppRoutes.homeInventoryManualAdd);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _scrollIntoView(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(Scrollable).first,
    const Offset(0, -200),
  );
  await _pumpUi(tester);
}

Future<void> _pressFilledButton(WidgetTester tester, Finder finder) async {
  final button = tester.widget<FilledButton>(finder);
  expect(button.onPressed, isNotNull);
  button.onPressed!.call();
  await tester.pumpAndSettle();
}

Future<void> _setCheckboxValue(
  WidgetTester tester,
  Finder finder,
  bool value,
) async {
  final checkbox = tester.widget<CheckboxListTile>(finder);
  expect(checkbox.onChanged, isNotNull);
  checkbox.onChanged!(value);
  await _pumpUi(tester);
  expect(tester.widget<CheckboxListTile>(finder).value, value);
}

void _installFakeScannerPlatform(WidgetTester tester) {
  final previousPlatform = MobileScannerPlatform.instance;
  final fakePlatform = _FakeMobileScannerPlatform();
  MobileScannerPlatform.instance = fakePlatform;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    MobileScannerPlatform.instance = previousPlatform;
    await fakePlatform.shutdown();
  });
}

_FakeMobileScannerPlatform _fakeScannerPlatform() {
  return MobileScannerPlatform.instance as _FakeMobileScannerPlatform;
}

void main() {
  testWidgets('single barcode result needs explicit confirmation before save', (
    tester,
  ) async {
    _installFakeScannerPlatform(tester);

    final offRepository =
        _RecordingOffProductSearchRepository(<OffProductSearchResult>[
          OffProductSearchResult(
            code: '4006381333931',
            name: 'Milk',
            brand: 'Brand',
            score: 99,
            packageWeight: '1 l',
            imageUrl: 'https://example.com/milk.png',
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 100,
              per100Protein: 10,
              per100Carbs: 20,
              per100Fat: 3,
            ),
          ),
        ]);
    final inventoryRepository = _RecordingInventoryItemRepository();
    addTearDown(inventoryRepository.dispose);
    final globalFoodRepository = _RecordingGlobalFoodItemRepository();
    final barcodeCandidateRepository =
        _RecordingGlobalBarcodeCandidateRepository();

    await tester.pumpWidget(
      _buildHarness(
        offRepository: offRepository,
        inventoryRepository: inventoryRepository,
        globalFoodRepository: globalFoodRepository,
        barcodeCandidateRepository: barcodeCandidateRepository,
      ),
    );
    await _pumpUi(tester);

    expect(
      find.byKey(const Key('receipt_review_manual_launcher_search_field')),
      findsOneWidget,
    );
    final scanButton = find.byKey(
      const Key('receipt_review_manual_scan_button'),
    );
    await tester.tap(scanButton);
    await _pumpUi(tester);

    _fakeScannerPlatform().emitBarcode('4006381333931');
    await _pumpUi(tester);

    expect(offRepository.lastBarcode, '4006381333931');
    expect(inventoryRepository.appendedItems, isEmpty);
    expect(globalFoodRepository.appendedItems, isEmpty);
    final searchField = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_manual_search_field')),
    );
    final previewName = tester.widget<Text>(
      find.byKey(const Key('receipt_review_manual_preview_name')),
    );
    expect(searchField.controller?.text, 'Milk');
    expect(previewName.data, 'Milk');
    expect(
      find.descendant(
        of: find.byKey(const Key('receipt_review_manual_preview')),
        matching: find.text('Brand'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('receipt_review_manual_preview')),
        matching: find.text('1000 ml'),
      ),
      findsOneWidget,
    );

    final manualSaveButton = find.byKey(
      const Key('receipt_review_manual_save_button'),
    );
    await tester.ensureVisible(manualSaveButton);
    await tester.tap(manualSaveButton);
    await _pumpUi(tester);

    expect(find.text('home'), findsOneWidget);
    expect(globalFoodRepository.appendedItems, hasLength(1));
    expect(globalFoodRepository.appendedItems.single.id, 'off-4006381333931');
    expect(inventoryRepository.appendedItems, hasLength(1));
    expect(inventoryRepository.appendedItems.single.name, 'Milk');
    expect(
      inventoryRepository.appendedItems.single.storeName,
      'Added manually',
    );
    expect(
      inventoryRepository.appendedItems.single.globalFoodItemId,
      'off-4006381333931',
    );
    expect(
      inventoryRepository.appendedItems.single.origin,
      InventoryItemOrigin.manualAdd,
    );
    expect(barcodeCandidateRepository.recordedSelections, hasLength(1));
    expect(
      barcodeCandidateRepository.recordedSelections.single.barcode,
      '4006381333931',
    );
  });

  testWidgets(
    'eat now stays disabled when the manual product has no nutrition',
    (tester) async {
      _installFakeScannerPlatform(tester);

      final offRepository =
          _RecordingOffProductSearchRepository(<OffProductSearchResult>[
            const OffProductSearchResult(
              code: '4316268671224',
              name: 'Cashews Sour Creme & Onion',
              brand: 'Clarkys',
              score: 100,
            ),
          ]);
      final inventoryRepository = _RecordingInventoryItemRepository();
      addTearDown(inventoryRepository.dispose);
      final globalFoodRepository = _RecordingGlobalFoodItemRepository();

      await tester.pumpWidget(
        _buildHarness(
          offRepository: offRepository,
          inventoryRepository: inventoryRepository,
          globalFoodRepository: globalFoodRepository,
        ),
      );
      await _pumpUi(tester);

      await tester.tap(
        find.byKey(const Key('receipt_review_manual_scan_button')),
      );
      await _pumpUi(tester);

      _fakeScannerPlatform().emitBarcode('4316268671224');
      await _pumpUi(tester);

      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('receipt_review_manual_eat_now_checkbox')),
      );
      expect(checkbox.enabled, isFalse);
      expect(
        find.text('Only available when nutrition values are present.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('eat now opens the eat flow after the product was saved', (
    tester,
  ) async {
    _installFakeScannerPlatform(tester);

    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('user-1');

    final offRepository =
        _RecordingOffProductSearchRepository(<OffProductSearchResult>[
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
              per100Protein: 10,
              per100Carbs: 20,
              per100Fat: 3,
            ),
          ),
        ]);
    final inventoryRepository = _RecordingInventoryItemRepository();
    addTearDown(inventoryRepository.dispose);
    final globalFoodRepository = _RecordingGlobalFoodItemRepository();
    final calorieLogRepository = FakeCalorieLogRepository();
    addTearDown(calorieLogRepository.dispose);
    final calorieProductCacheRepository = FakeCalorieProductCacheRepository();
    final inventoryCommitStore = _RecordingInventoryCalorieEntryCommitStore();

    await tester.pumpWidget(
      _buildHarness(
        auth: auth,
        offRepository: offRepository,
        inventoryRepository: inventoryRepository,
        globalFoodRepository: globalFoodRepository,
        calorieLogRepository: calorieLogRepository,
        calorieProductCacheRepository: calorieProductCacheRepository,
        inventoryCommitStore: inventoryCommitStore,
      ),
    );
    await _pumpUi(tester);

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_scan_button')),
    );
    await _pumpUi(tester);

    _fakeScannerPlatform().emitBarcode('4006381333931');
    await _pumpUi(tester);

    final eatNowCheckbox = find.byKey(
      const Key('receipt_review_manual_eat_now_checkbox'),
    );
    await tester.ensureVisible(eatNowCheckbox);
    await _setCheckboxValue(tester, eatNowCheckbox, true);
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_eat_now_weight_field')),
      '250',
    );
    await _pumpUi(tester);

    final manualSaveButton = find.byKey(
      const Key('receipt_review_manual_save_button'),
    );
    await _scrollIntoView(tester, manualSaveButton);
    await _pressFilledButton(tester, manualSaveButton);

    expect(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      findsOneWidget,
    );
    final amountField = tester.widget<TextField>(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
    );
    expect(amountField.controller?.text, '250');
    expect(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
      findsOneWidget,
    );

    final logButton = find.text('Log');
    await tester.ensureVisible(logButton);
    await tester.tap(logButton);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(inventoryCommitStore.pendingConsumption, isNotNull);
    expect(inventoryCommitStore.pendingConsumption?.itemId, isNotEmpty);
    expect(inventoryCommitStore.pendingConsumption?.amount, 250);
  });

  testWidgets(
    'eat now shows save error and does not open eat flow when persisting fails',
    (tester) async {
      _installFakeScannerPlatform(tester);

      final offRepository =
          _RecordingOffProductSearchRepository(<OffProductSearchResult>[
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
                per100Protein: 10,
                per100Carbs: 20,
                per100Fat: 3,
              ),
            ),
          ]);
      final inventoryRepository = _FailingInventoryItemRepository();
      addTearDown(inventoryRepository.dispose);
      final globalFoodRepository = _RecordingGlobalFoodItemRepository();

      await tester.pumpWidget(
        _buildHarness(
          offRepository: offRepository,
          inventoryRepository: inventoryRepository,
          globalFoodRepository: globalFoodRepository,
        ),
      );
      await _pumpUi(tester);

      await tester.tap(
        find.byKey(const Key('receipt_review_manual_scan_button')),
      );
      await _pumpUi(tester);

      _fakeScannerPlatform().emitBarcode('4006381333931');
      await _pumpUi(tester);

      final eatNowCheckbox = find.byKey(
        const Key('receipt_review_manual_eat_now_checkbox'),
      );
      await tester.ensureVisible(eatNowCheckbox);
      await _setCheckboxValue(tester, eatNowCheckbox, true);

      final manualSaveButton = find.byKey(
        const Key('receipt_review_manual_save_button'),
      );
      await _scrollIntoView(tester, manualSaveButton);
      await _pressFilledButton(tester, manualSaveButton);

      expect(
        find.text('The product could not be added to the inventory.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'eat now shows action error when staging pending consumption fails',
    (tester) async {
      _installFakeScannerPlatform(tester);

      final offRepository =
          _RecordingOffProductSearchRepository(<OffProductSearchResult>[
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
                per100Protein: 10,
                per100Carbs: 20,
                per100Fat: 3,
              ),
            ),
          ]);
      final inventoryRepository = _RecordingInventoryItemRepository();
      addTearDown(inventoryRepository.dispose);
      final globalFoodRepository = _RecordingGlobalFoodItemRepository();

      await tester.pumpWidget(
        _buildHarness(
          offRepository: offRepository,
          inventoryRepository: inventoryRepository,
          globalFoodRepository: globalFoodRepository,
          inventoryItemsControllerFactory: () {
            return _FailingStageInventoryItemsController();
          },
        ),
      );
      await _pumpUi(tester);

      await tester.tap(
        find.byKey(const Key('receipt_review_manual_scan_button')),
      );
      await _pumpUi(tester);

      _fakeScannerPlatform().emitBarcode('4006381333931');
      await _pumpUi(tester);

      final eatNowCheckbox = find.byKey(
        const Key('receipt_review_manual_eat_now_checkbox'),
      );
      await tester.ensureVisible(eatNowCheckbox);
      await _setCheckboxValue(tester, eatNowCheckbox, true);

      final manualSaveButton = find.byKey(
        const Key('receipt_review_manual_save_button'),
      );
      await _scrollIntoView(tester, manualSaveButton);
      await _pressFilledButton(tester, manualSaveButton);

      expect(
        find.byKey(const Key('inventory_item_amount_dialog_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
        findsOneWidget,
      );

      final logButton = find.text('Log');
      await tester.ensureVisible(logButton);
      await tester.tap(logButton);
      await tester.pumpAndSettle();

      expect(find.text('Action failed. Please try again.'), findsOneWidget);
    },
  );

  testWidgets('multiple barcode candidates can be selected before saving', (
    tester,
  ) async {
    _installFakeScannerPlatform(tester);

    final offRepository =
        _RecordingOffProductSearchRepository(<OffProductSearchResult>[
          const OffProductSearchResult(
            code: '4316268671224',
            name: 'Cashews Sour Creme & Onion',
            brand: 'Clarkys',
            score: 100,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 550,
              per100Protein: 8,
              per100Carbs: 30,
              per100Fat: 40,
            ),
          ),
          const OffProductSearchResult(
            code: '4316268671225',
            name: 'Cashews Paprika',
            brand: 'Clarkys',
            score: 90,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 560,
              per100Protein: 7,
              per100Carbs: 31,
              per100Fat: 41,
            ),
          ),
        ]);
    final inventoryRepository = _RecordingInventoryItemRepository();
    addTearDown(inventoryRepository.dispose);
    final globalFoodRepository = _RecordingGlobalFoodItemRepository();

    await tester.pumpWidget(
      _buildHarness(
        offRepository: offRepository,
        inventoryRepository: inventoryRepository,
        globalFoodRepository: globalFoodRepository,
      ),
    );
    await _pumpUi(tester);

    expect(
      find.byKey(const Key('receipt_review_manual_launcher_search_field')),
      findsOneWidget,
    );
    final scanButton = find.byKey(
      const Key('receipt_review_manual_scan_button'),
    );
    await tester.tap(scanButton);
    await _pumpUi(tester);

    _fakeScannerPlatform().emitBarcode('4316268671224');
    await _pumpUi(tester);

    expect(find.text('Cashews Paprika'), findsOneWidget);

    await tester.tap(find.text('Cashews Paprika'));
    await _pumpUi(tester);

    expect(inventoryRepository.appendedItems, isEmpty);

    final manualSaveButton = find.byKey(
      const Key('receipt_review_manual_save_button'),
    );
    await tester.ensureVisible(manualSaveButton);
    await tester.tap(manualSaveButton);
    await _pumpUi(tester);

    expect(inventoryRepository.appendedItems, hasLength(1));
    expect(inventoryRepository.appendedItems.single.name, 'Cashews Paprika');
    expect(inventoryRepository.appendedItems.single.barcode, '4316268671225');
    expect(
      inventoryRepository.appendedItems.single.origin,
      InventoryItemOrigin.manualAdd,
    );
  });

  testWidgets('learned barcode candidate can be selected and voted', (
    tester,
  ) async {
    _installFakeScannerPlatform(tester);

    final offRepository =
        _RecordingOffProductSearchRepository(<OffProductSearchResult>[
          const OffProductSearchResult(
            code: '4006381333931',
            name: 'OFF Milk',
            brand: 'OFF Brand',
            score: 99,
          ),
        ]);
    final inventoryRepository = _RecordingInventoryItemRepository();
    addTearDown(inventoryRepository.dispose);
    final globalFoodRepository = _RecordingGlobalFoodItemRepository();
    final barcodeCandidateRepository =
        _RecordingGlobalBarcodeCandidateRepository(
          candidates: <GlobalBarcodeCandidate>[
            GlobalBarcodeCandidate(
              id: 'barcode-4006381333931-community-milk',
              barcode: '4006381333931',
              globalFoodItemId: 'community-milk',
              selectionCount: 7,
              uniqueUserCount: 3,
              completenessScore: 10,
              globalFoodItem: GlobalFoodItem.create(
                id: 'community-milk',
                name: 'Community Milk',
                now: DateTime.parse('2026-04-13T10:00:00Z'),
                brand: 'Acme',
                barcode: '4006381333931',
                packageWeight: '1 l',
                nutrition: const GlobalFoodNutrition(
                  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
                  per100Kcal: 100,
                  per100Protein: 10,
                  per100Carbs: 20,
                  per100Fat: 3,
                ),
              ),
              createdAt: DateTime.parse('2026-04-13T10:00:00Z'),
              updatedAt: DateTime.parse('2026-04-13T10:00:00Z'),
            ),
          ],
        );

    await tester.pumpWidget(
      _buildHarness(
        offRepository: offRepository,
        inventoryRepository: inventoryRepository,
        globalFoodRepository: globalFoodRepository,
        barcodeCandidateRepository: barcodeCandidateRepository,
      ),
    );
    await _pumpUi(tester);

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_scan_button')),
    );
    await _pumpUi(tester);

    _fakeScannerPlatform().emitBarcode('4006381333931');
    await _pumpUi(tester);

    expect(find.text('Community Milk'), findsOneWidget);
    expect(find.text('OFF Milk'), findsOneWidget);

    await tester.tap(find.text('Community Milk'));
    await _pumpUi(tester);

    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('receipt_review_manual_preview_name')),
          )
          .data,
      'Community Milk',
    );

    final manualSaveButton = find.byKey(
      const Key('receipt_review_manual_save_button'),
    );
    await tester.ensureVisible(manualSaveButton);
    await tester.tap(manualSaveButton);
    await _pumpUi(tester);

    expect(globalFoodRepository.appendedItems, isEmpty);
    expect(
      inventoryRepository.appendedItems.single.globalFoodItemId,
      'community-milk',
    );
    expect(barcodeCandidateRepository.recordedSelections, hasLength(1));
    expect(
      barcodeCandidateRepository.recordedSelections.single.globalFoodItem.id,
      'community-milk',
    );
    expect(
      barcodeCandidateRepository
          .recordedSelections
          .single
          .globalFoodItem
          .packageWeight,
      '1000 ml',
    );
  });

  testWidgets(
    'learned candidate keeps package size when eat now amount is smaller',
    (tester) async {
      _installFakeScannerPlatform(tester);

      final offRepository =
          _RecordingOffProductSearchRepository(<OffProductSearchResult>[
            const OffProductSearchResult(
              code: '4006381333931',
              name: 'OFF Milk',
              brand: 'OFF Brand',
              score: 99,
            ),
          ]);
      final inventoryRepository = _RecordingInventoryItemRepository();
      addTearDown(inventoryRepository.dispose);
      final globalFoodRepository = _RecordingGlobalFoodItemRepository();
      final barcodeCandidateRepository =
          _RecordingGlobalBarcodeCandidateRepository(
            candidates: <GlobalBarcodeCandidate>[
              GlobalBarcodeCandidate(
                id: 'barcode-4006381333931-community-milk',
                barcode: '4006381333931',
                globalFoodItemId: 'community-milk',
                selectionCount: 7,
                uniqueUserCount: 3,
                completenessScore: 10,
                globalFoodItem: GlobalFoodItem.create(
                  id: 'community-milk',
                  name: 'Community Milk',
                  now: DateTime.parse('2026-04-13T10:00:00Z'),
                  brand: 'Acme',
                  barcode: '4006381333931',
                  packageWeight: '1 l',
                  nutrition: const GlobalFoodNutrition(
                    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
                    per100Kcal: 100,
                    per100Protein: 10,
                    per100Carbs: 20,
                    per100Fat: 3,
                  ),
                ),
                createdAt: DateTime.parse('2026-04-13T10:00:00Z'),
                updatedAt: DateTime.parse('2026-04-13T10:00:00Z'),
              ),
            ],
          );

      await tester.pumpWidget(
        _buildHarness(
          offRepository: offRepository,
          inventoryRepository: inventoryRepository,
          globalFoodRepository: globalFoodRepository,
          barcodeCandidateRepository: barcodeCandidateRepository,
        ),
      );
      await _pumpUi(tester);

      await tester.tap(
        find.byKey(const Key('receipt_review_manual_scan_button')),
      );
      await _pumpUi(tester);

      _fakeScannerPlatform().emitBarcode('4006381333931');
      await _pumpUi(tester);

      await tester.tap(find.text('Community Milk'));
      await _pumpUi(tester);

      final eatNowCheckbox = find.byKey(
        const Key('receipt_review_manual_eat_now_checkbox'),
      );
      await tester.ensureVisible(eatNowCheckbox);
      await _setCheckboxValue(tester, eatNowCheckbox, true);
      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_eat_now_weight_field')),
        '250',
      );
      await _pumpUi(tester);

      final manualSaveButton = find.byKey(
        const Key('receipt_review_manual_save_button'),
      );
      await tester.ensureVisible(manualSaveButton);
      await tester.tap(manualSaveButton);
      await _pumpUi(tester);

      expect(globalFoodRepository.appendedItems, isEmpty);
      expect(
        barcodeCandidateRepository
            .recordedSelections
            .single
            .globalFoodItem
            .packageWeight,
        '1000 ml',
      );
      expect(inventoryRepository.appendedItems.single.weight, '1000 ml');
    },
  );

  test('resolveInventoryManualAddEatFlowMaxAmount guards invalid items', () {
    final quantitylessItem = InventoryItem.create(
      id: 'item-0',
      name: 'Nothing',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 0,
    );
    final depletedAmountItem = InventoryItem.create(
      id: 'item-1',
      name: 'Milk',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 1,
      initialAmount: 1000,
      currentAmount: 0,
      amountUnit: InventoryAmountUnit.milliliter,
    );

    expect(resolveInventoryManualAddEatFlowMaxAmount(quantitylessItem), isNull);
    expect(
      resolveInventoryManualAddEatFlowMaxAmount(depletedAmountItem),
      isNull,
    );
  });
}
