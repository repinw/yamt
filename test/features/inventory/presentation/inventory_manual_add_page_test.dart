import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _RecordingInventoryItemRepository implements InventoryItemRepository {
  final List<InventoryItem> appendedItems = <InventoryItem>[];

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    appendedItems.addAll(items);
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return const Stream<List<InventoryItem>>.empty();
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
            nutrition: const GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 100,
              per100Protein: 10,
              per100Carbs: 20,
              per100Fat: 3,
            ),
          ),
        ]);
    final inventoryRepository = _RecordingInventoryItemRepository();
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
      find.byKey(const Key('receipt_review_manual_search_field')),
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
    expect(
      globalFoodRepository.appendedItems.single.id,
      'off-4006381333931-milk-brand',
    );
    expect(inventoryRepository.appendedItems, hasLength(1));
    expect(inventoryRepository.appendedItems.single.name, 'Milk');
    expect(
      inventoryRepository.appendedItems.single.storeName,
      'Added manually',
    );
    expect(
      inventoryRepository.appendedItems.single.globalFoodItemId,
      'off-4006381333931-milk-brand',
    );
  });

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
          ),
          const OffProductSearchResult(
            code: '4316268671225',
            name: 'Cashews Paprika',
            brand: 'Clarkys',
            score: 90,
          ),
        ]);
    final inventoryRepository = _RecordingInventoryItemRepository();
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
      find.byKey(const Key('receipt_review_manual_search_field')),
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
  });
}
