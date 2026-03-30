import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/'
    'calorie_barcode_scan_page.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_barcode_candidate_picker_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

CalorieProductProfile _profile({
  required String barcode,
  required String name,
  required CalorieProductSource source,
}) {
  final now = DateTime(2026, 2, 25, 10);
  return CalorieProductProfile(
    barcode: barcode,
    name: name,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 20,
    per100Fat: 3,
    source: source,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  _FakeMobileScannerPlatform();

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
  Future<Set<CameraLensType>> getSupportedLenses() async {
    return <CameraLensType>{CameraLensType.any};
  }

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
  Future<void> pause() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> setFocusPoint(Offset position) async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {
    // The real controller awaits platform.dispose() during widget teardown.
    // Closing the backing streams here can deadlock while listeners are
    // still attached, so test cleanup shuts them down explicitly later.
  }

  Future<void> shutdown() async {
    await _barcodeController.close();
    await _torchController.close();
    await _zoomController.close();
  }

  void emitBarcode(String rawValue) {
    _barcodeController.add(
      BarcodeCapture(barcodes: <Barcode>[Barcode(rawValue: rawValue)]),
    );
  }
}

Widget _buildHarness({
  required FakeCalorieProductLookupRepository lookupRepository,
  required FakeCalorieNutritionOcrRepository ocrRepository,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeCaloriesBarcodeScan,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.homeCaloriesBarcodeScan,
        builder: (context, state) {
          return const CalorieBarcodeScanPage();
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        builder: (context, state) {
          final args = state.extra as CalorieEntryCreateArgs?;
          final name = args?.prefilledProfile?.name;
          if (name == null) {
            return const Scaffold(body: Text('manual-create'));
          }
          return Scaffold(body: Text('create:$name'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      calorieProductLookupRepositoryProvider.overrideWithValue(
        lookupRepository,
      ),
      calorieNutritionOcrRepositoryProvider.overrideWithValue(ocrRepository),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
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
  testWidgets('ignores queued barcode callback after page disposal', (
    tester,
  ) async {
    _installFakeScannerPlatform(tester);

    final lookupRepository = FakeCalorieProductLookupRepository(
      onLookupByBarcode: (_) async => const CalorieLookupOutcome.notFound(),
    );
    final ocrRepository = FakeCalorieNutritionOcrRepository(
      onScanNutritionLabel: (_) async {
        return const CalorieNutritionOcrResult.failed(errorCode: 'unused');
      },
    );

    await tester.pumpWidget(
      _buildHarness(
        lookupRepository: lookupRepository,
        ocrRepository: ocrRepository,
      ),
    );
    await _pumpUi(tester);

    _fakeScannerPlatform().emitBarcode('4006381333931');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple lookup outcome shows candidate picker bottom sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _installFakeScannerPlatform(tester);

    final first = _profile(
      barcode: '4006381333931',
      name: 'First',
      source: CalorieProductSource.offSearch,
    );
    final second = _profile(
      barcode: '4006381333931',
      name: 'Second',
      source: CalorieProductSource.offSearch,
    );
    final lookupRepository = FakeCalorieProductLookupRepository(
      onLookupByBarcode: (_) async {
        return CalorieLookupOutcome.foundMultiple(<CalorieProductCandidate>[
          CalorieProductCandidate(profile: first, completenessScore: 9),
          CalorieProductCandidate(profile: second, completenessScore: 8),
        ]);
      },
    );
    final ocrRepository = FakeCalorieNutritionOcrRepository(
      onScanNutritionLabel: (_) async {
        return const CalorieNutritionOcrResult.failed(errorCode: 'unused');
      },
    );

    await tester.pumpWidget(
      _buildHarness(
        lookupRepository: lookupRepository,
        ocrRepository: ocrRepository,
      ),
    );
    await _pumpUi(tester);

    _fakeScannerPlatform().emitBarcode('4006381333931');
    await _pumpUi(tester);

    expect(find.byKey(CalorieBarcodeScanKeys.candidateSheet), findsOneWidget);
  });

  testWidgets('single lookup outcome opens editor with prefilled profile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _installFakeScannerPlatform(tester);

    final first = _profile(
      barcode: '4006381333931',
      name: 'First',
      source: CalorieProductSource.offBarcode,
    );

    final lookupRepository = FakeCalorieProductLookupRepository(
      onLookupByBarcode: (_) async {
        return CalorieLookupOutcome.foundSingle(first);
      },
    );
    final ocrRepository = FakeCalorieNutritionOcrRepository(
      onScanNutritionLabel: (_) async {
        return const CalorieNutritionOcrResult.failed(errorCode: 'unused');
      },
    );

    await tester.pumpWidget(
      _buildHarness(
        lookupRepository: lookupRepository,
        ocrRepository: ocrRepository,
      ),
    );
    await _pumpUi(tester);

    _fakeScannerPlatform().emitBarcode('4006381333931');
    await _pumpUi(tester);
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('create:First'), findsOneWidget);
  });

  testWidgets('candidate picker calls onSelect when candidate is tapped', (
    tester,
  ) async {
    CalorieProductCandidate? selected;
    final profile = _profile(
      barcode: '4006381333931',
      name: 'First',
      source: CalorieProductSource.offSearch,
    );
    final candidate = CalorieProductCandidate(
      profile: profile,
      completenessScore: 9,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CalorieBarcodeCandidatePickerSheet(
            candidates: <CalorieProductCandidate>[candidate],
            onSelect: (value) {
              selected = value;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('First'));
    await tester.pump();

    expect(selected?.profile.name, 'First');
  });

  testWidgets('not-found manual action opens manual create route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _installFakeScannerPlatform(tester);

    final lookupRepository = FakeCalorieProductLookupRepository(
      onLookupByBarcode: (_) async => const CalorieLookupOutcome.notFound(),
    );
    final ocrRepository = FakeCalorieNutritionOcrRepository(
      onScanNutritionLabel: (_) async {
        return const CalorieNutritionOcrResult.failed(errorCode: 'unused');
      },
    );

    await tester.pumpWidget(
      _buildHarness(
        lookupRepository: lookupRepository,
        ocrRepository: ocrRepository,
      ),
    );
    await _pumpUi(tester);

    _fakeScannerPlatform().emitBarcode('4006381333931');
    await _pumpUi(tester);

    expect(find.byKey(CalorieBarcodeScanKeys.notFoundDialog), findsOneWidget);
    await tester.tap(find.byKey(CalorieBarcodeScanKeys.notFoundManualButton));
    await _pumpUi(tester);

    expect(find.text('manual-create'), findsOneWidget);
  });

  testWidgets('not-found OCR action opens editor with OCR-prefilled values', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _installFakeScannerPlatform(tester);

    final ocrProfile = _profile(
      barcode: '4006381333931',
      name: 'OCR Item',
      source: CalorieProductSource.ocr,
    );

    final lookupRepository = FakeCalorieProductLookupRepository(
      onLookupByBarcode: (_) async => const CalorieLookupOutcome.notFound(),
    );
    final ocrRepository = FakeCalorieNutritionOcrRepository(
      onScanNutritionLabel: (_) async {
        return CalorieNutritionOcrResult.succeeded(profile: ocrProfile);
      },
    );

    await tester.pumpWidget(
      _buildHarness(
        lookupRepository: lookupRepository,
        ocrRepository: ocrRepository,
      ),
    );
    await _pumpUi(tester);

    _fakeScannerPlatform().emitBarcode('4006381333931');
    await _pumpUi(tester);

    await tester.tap(find.byKey(CalorieBarcodeScanKeys.notFoundOcrButton));
    await _pumpUi(tester);

    expect(find.text('create:OCR Item'), findsOneWidget);
  });
}
