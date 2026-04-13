import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository_contract.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _item({
  required String id,
  required bool isDeposit,
  required bool isDiscount,
  String? name,
  DateTime? receiptDate,
  String storeName = 'Store',
  String? brand,
  String? weight,
  int quantity = 1,
  double unitPrice = 1.0,
  String? currencyCode,
  GlobalFoodNutrition? nutrition,
  Map<String, double> discounts = const <String, double>{},
}) {
  return InventoryItem.create(
    id: id,
    name: name ?? 'Item $id',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: storeName,
    quantity: quantity,
    unitPrice: unitPrice,
    currencyCode: currencyCode,
    brand: brand,
    weight: weight,
    nutrition: nutrition,
    discounts: discounts,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
    receiptDate: receiptDate,
  );
}

const _testNutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 120,
);

Widget _wrap({
  List<InventoryItem>? items,
  List<ReceiptReviewItemDraft>? drafts,
  required VoidCallback onCancelTap,
  required Future<void> Function(List<InventoryItem> items) onSaveTap,
  Uint8List? receiptPreviewBytes,
  List<Override> overrides = const <Override>[],
}) {
  assert((items == null) != (drafts == null));

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InventoryReceiptReviewSheet(
          items:
              drafts ??
              items!
                  .map((item) => ReceiptReviewItemDraft(item: item))
                  .toList(growable: false),
          receiptPreviewBytes: receiptPreviewBytes,
          onCancelTap: onCancelTap,
          onSaveTap: (drafts) {
            return onSaveTap(
              drafts.map((draft) => draft.item).toList(growable: false),
            );
          },
        ),
      ),
    ),
  );
}

class _RecordingOffProductSearchRepository
    implements OffProductSearchRepository {
  _RecordingOffProductSearchRepository(this.results);

  final List<OffProductSearchResult> results;
  String? lastQuery;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    lastQuery = query;
    return results.take(limit).toList(growable: false);
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return results;
  }
}

class _CompletingOffProductSearchRepository
    implements OffProductSearchRepository {
  _CompletingOffProductSearchRepository();

  final Completer<List<OffProductSearchResult>> completer =
      Completer<List<OffProductSearchResult>>();

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) {
    return completer.future;
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) {
    return completer.future;
  }
}

class _FakeNutritionOcrRepository
    implements CalorieNutritionOcrRepositoryContract {
  _FakeNutritionOcrRepository({required this.onScanNutritionLabel});

  final Future<CalorieNutritionOcrResult> Function(String barcode)
  onScanNutritionLabel;

  @override
  Future<CalorieNutritionOcrResult> scanNutritionLabel({
    required String barcode,
  }) {
    return onScanNutritionLabel(barcode);
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

Future<void> _confirmReviewItem(WidgetTester tester, int index) async {
  final button = find.byKey(Key('receipt_review_confirm_button_$index'));
  expect(button, findsOneWidget);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

GlobalFoodMatchCandidate _candidate({
  required String id,
  required String name,
  String? brand,
  String? barcode,
  String? imageUrl,
  String? packageWeight,
}) {
  return GlobalFoodMatchCandidate(
    item: GlobalFoodItem.create(
      id: id,
      name: name,
      now: DateTime.parse('2026-02-19T10:00:00Z'),
      brand: brand,
      barcode: barcode,
      imageUrl: imageUrl,
      packageWeight: packageWeight,
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 120,
      ),
    ),
    score: 0.9,
    reason: GlobalFoodMatchReason.nameBrandStrong,
  );
}

final Uint8List _receiptPreviewPng = Uint8List.fromList(const <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x03,
  0x01,
  0x01,
  0x00,
  0x18,
  0xDD,
  0x8D,
  0xB1,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  testWidgets('price overview shows total, savable and excluded sums', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
          _item(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    await tester.scrollUntilVisible(
      find.text(l10n.inventoryReceiptReviewPriceTitle),
      200,
    );

    expect(find.text(l10n.inventoryReceiptReviewPriceTitle), findsOneWidget);
    expect(find.text(l10n.inventoryReceiptReviewPriceTotal), findsOneWidget);
    expect(find.text(l10n.inventoryReceiptReviewPriceSavable), findsOneWidget);
    expect(find.text(l10n.inventoryReceiptReviewPriceExcluded), findsOneWidget);
  });

  testWidgets('preview button opens receipt image dialog', (tester) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        receiptPreviewBytes: _receiptPreviewPng,
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_preview_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('receipt_review_preview_button')));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('switch action opens candidate sheet and updates pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'KÄSE SCHEIBEN 150G',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(id: 'gouda', name: 'Gouda', brand: 'Milbona'),
              _candidate(id: 'edamer', name: 'Edamer', brand: 'Milbona'),
            ],
            ocrName: 'KÄSE SCHEIBEN 150G',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_switch_button_0')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    expect(
      find.text(l10n.inventoryReceiptReviewProductSelectionLabel),
      findsOneWidget,
    );
    expect(find.text('Gouda'), findsOneWidget);

    await tester.tap(find.text('Gouda').last);
    await tester.pumpAndSettle();

    expect(find.text('Gouda'), findsOneWidget);
  });

  testWidgets('preselected candidate data is kept on save after confirm', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'OCR KAESE',
              brand: 'OCR Brand',
              weight: '500 g',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(
                id: 'gouda',
                name: 'Gouda Jung',
                brand: 'Milbona',
                barcode: '4000123456789',
                imageUrl: 'https://example.com/gouda.png',
                packageWeight: '500 g',
              ),
            ],
            selectedGlobalFoodItemId: 'gouda',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_confirm_button_0')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.name, 'Gouda Jung');
    expect(savedItems!.single.brand, 'Milbona');
    expect(savedItems!.single.barcode, '4000123456789');
    expect(savedItems!.single.imageUrl, 'https://example.com/gouda.png');
  });

  testWidgets('switched candidate data is kept on save after confirm', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'OCR KAESE',
              brand: 'OCR Brand',
              weight: '500 g',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(
                id: 'gouda',
                name: 'Gouda Jung',
                brand: 'Milbona',
                barcode: '4000123456789',
                packageWeight: '500 g',
              ),
              _candidate(
                id: 'edamer',
                name: 'Edamer Mild',
                brand: 'Ja!',
                barcode: '4000987654321',
                imageUrl: 'https://example.com/edamer.png',
                packageWeight: '500 g',
              ),
            ],
            ocrName: 'KAESE SCHEIBEN',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_switch_button_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edamer Mild').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('receipt_review_confirm_button_0')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.name, 'Edamer Mild');
    expect(savedItems!.single.brand, 'Ja!');
    expect(savedItems!.single.barcode, '4000987654321');
    expect(savedItems!.single.imageUrl, 'https://example.com/edamer.png');
  });

  testWidgets('editing selected candidate updates preview card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'OCR KAESE',
              brand: 'OCR Brand',
              weight: '500 g',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(
                id: 'gouda',
                name: 'Gouda Jung',
                brand: 'Milbona',
                barcode: '4000123456789',
                imageUrl: 'https://example.com/gouda.png',
                packageWeight: '500 g',
              ),
            ],
            selectedGlobalFoodItemId: 'gouda',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('Gouda Jung'), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_name')),
      'Edited Gouda',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Edited Gouda'), findsOneWidget);
    expect(find.text('Gouda Jung'), findsNothing);
  });

  testWidgets(
    'switching candidate with changed receipt weight keeps receipt weight',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          drafts: <ReceiptReviewItemDraft>[
            ReceiptReviewItemDraft(
              item: _item(
                id: 'food',
                isDeposit: false,
                isDiscount: false,
                name: 'KAESE SCHEIBEN',
                weight: '500g',
              ),
              candidates: <GlobalFoodMatchCandidate>[
                _candidate(
                  id: 'gouda',
                  name: 'Gouda',
                  brand: 'Milbona',
                  packageWeight: '800g',
                ),
              ],
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (_) async {},
        ),
      );

      await tester.tap(find.byKey(const Key('receipt_review_switch_button_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gouda').last);
      await tester.pumpAndSettle();

      expect(find.text('Gouda'), findsOneWidget);
      expect(find.text('500g'), findsOneWidget);
      expect(find.text('800g'), findsNothing);
    },
  );

  testWidgets(
    'switching candidate with missing receipt weight uses candidate weight',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          drafts: <ReceiptReviewItemDraft>[
            ReceiptReviewItemDraft(
              item: _item(
                id: 'food',
                isDeposit: false,
                isDiscount: false,
                name: 'KÄSE SCHEIBEN',
              ),
              candidates: <GlobalFoodMatchCandidate>[
                _candidate(
                  id: 'gouda',
                  name: 'Gouda',
                  brand: 'Milbona',
                  packageWeight: '800g',
                ),
              ],
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (_) async {},
        ),
      );

      await tester.tap(find.byKey(const Key('receipt_review_switch_button_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gouda').last);
      await tester.pumpAndSettle();

      expect(find.text('Gouda'), findsOneWidget);
      expect(find.text('800g'), findsOneWidget);
    },
  );

  testWidgets('confirm button toggles between check and undo', (tester) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            name: 'KÄSE SCHEIBEN',
            weight: '800g',
            nutrition: _testNutrition,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsNothing);

    await _confirmReviewItem(tester, 0);

    expect(find.byIcon(Icons.undo), findsOneWidget);

    await _confirmReviewItem(tester, 0);

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('determine action fetches candidates and opens candidate sheet', (
    tester,
  ) async {
    final externalRepository =
        _RecordingOffProductSearchRepository(<OffProductSearchResult>[
          const OffProductSearchResult(
            code: '4061458029995',
            name: 'Waffelhörnchen Haselnuss-Vanille',
            brand: 'Aldi, Froneri, Mucci',
            packageWeight: '110 ml',
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 215,
              per100Protein: 4.2,
              per100Carbs: 24.8,
              per100Fat: 9.6,
              per100Salt: 0.4,
            ),
            score: 34,
          ),
        ]);
    final matcher = GlobalFoodItemMatcher(
      offProductSearchRepository: externalRepository,
    );

    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'Waffelh Edb/Nuss',
            ),
          ),
        ],
        overrides: <Override>[
          globalFoodItemMatcherProvider.overrideWithValue(matcher),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(
      find.byKey(const Key('receipt_review_determine_button_0')),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    expect(
      find.text(l10n.inventoryReceiptReviewProductSelectionLabel),
      findsOneWidget,
    );
    expect(
      find.text('Waffelhörnchen Haselnuss-Vanille'),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('110 ml'), findsAtLeastNWidgets(1));
    expect(find.textContaining('215 kcal'), findsAtLeastNWidgets(1));
    expect(externalRepository.lastQuery, 'Waffelh Edb/Nuss');
  });

  testWidgets('determine loading is tracked by item id', (tester) async {
    final externalRepository = _CompletingOffProductSearchRepository();
    final matcher = GlobalFoodItemMatcher(
      offProductSearchRepository: externalRepository,
    );

    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'first',
              isDeposit: false,
              isDiscount: false,
              name: 'First Product',
            ),
          ),
          ReceiptReviewItemDraft(
            item: _item(
              id: 'second',
              isDeposit: false,
              isDiscount: false,
              name: 'Second Product',
            ),
          ),
        ],
        overrides: <Override>[
          globalFoodItemMatcherProvider.overrideWithValue(matcher),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(
      find.byKey(const Key('receipt_review_determine_button_1')),
    );
    await tester.pump();

    final firstButton = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const Key('receipt_review_determine_button_0')),
        matching: find.byType(TextButton),
      ),
    );
    final secondButton = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const Key('receipt_review_determine_button_1')),
        matching: find.byType(TextButton),
      ),
    );

    expect(firstButton.onPressed, isNotNull);
    expect(secondButton.onPressed, isNull);

    externalRepository.completer.complete(const <OffProductSearchResult>[]);
    await tester.pumpAndSettle();
  });

  testWidgets('manual fallback saves entered barcode and nutrition', (
    tester,
  ) async {
    _installFakeScannerPlatform(tester);

    List<InventoryItem>? savedItems;
    final matcher = GlobalFoodItemMatcher(
      offProductSearchRepository: _RecordingOffProductSearchRepository(
        const <OffProductSearchResult>[],
      ),
    );

    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'Mystery Product',
            ),
          ),
        ],
        overrides: <Override>[
          globalFoodItemMatcherProvider.overrideWithValue(matcher),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(
      find.byKey(const Key('receipt_review_determine_button_0')),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.inventoryReceiptReviewManualDataAction));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_scan_button')),
    );
    await tester.pumpAndSettle();

    _fakeScannerPlatform().emitBarcode('4006381333931');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_kcal_field')),
      '120',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_protein_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_saturated_fat_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_carbs_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_sugar_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_fat_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_salt_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_weight_field')),
      '500',
    );
    final manualSaveButton = tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_manual_save_button')),
    );
    manualSaveButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('500 g'), findsOneWidget);

    await _confirmReviewItem(tester, 0);

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.barcode, '4006381333931');
    expect(savedItems!.single.nutrition?.per100Kcal, 120);
  });

  testWidgets(
    'manual fallback keeps OCR nutrition and manual name brand after barcode '
    'scan finds nothing',
    (tester) async {
      _installFakeScannerPlatform(tester);

      List<InventoryItem>? savedItems;
      final offRepository = _RecordingOffProductSearchRepository(
        const <OffProductSearchResult>[],
      );
      final matcher = GlobalFoodItemMatcher(
        offProductSearchRepository: offRepository,
      );
      final ocrRepository = _FakeNutritionOcrRepository(
        onScanNutritionLabel: (barcode) async {
          return CalorieNutritionOcrResult.succeeded(
            draft: CalorieNutritionOcrDraft(
              barcode: barcode,
              name: 'Manual OCR Product',
              brand: 'OCR Brand',
              per100Kcal: 321,
              per100SaturatedFat: 1.2,
              per100Protein: 12,
              per100Carbs: 22,
              per100Sugar: 8,
              per100Fat: 7,
              per100Salt: 0.5,
              per100PolyunsaturatedFat: null,
              per100Fiber: null,
            ),
          );
        },
      );

      await tester.pumpWidget(
        _wrap(
          drafts: <ReceiptReviewItemDraft>[
            ReceiptReviewItemDraft(
              item: _item(
                id: 'food',
                isDeposit: false,
                isDiscount: false,
                name: 'Mystery Product',
              ),
            ),
          ],
          overrides: <Override>[
            globalFoodItemMatcherProvider.overrideWithValue(matcher),
            offProductSearchRepositoryProvider.overrideWithValue(offRepository),
            calorieNutritionOcrRepositoryProvider.overrideWithValue(
              ocrRepository,
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (items) async {
            savedItems = items;
          },
        ),
      );

      await tester.tap(
        find.byKey(const Key('receipt_review_determine_button_0')),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(InventoryReceiptReviewSheet));
      final l10n = AppLocalizations.of(context)!;
      await tester.tap(find.text(l10n.inventoryReceiptReviewManualDataAction));
      await tester.pumpAndSettle();

      final ocrButtonFinder = find.byKey(
        const Key('receipt_review_manual_nutrition_ocr_button'),
      );
      expect(ocrButtonFinder, findsNothing);

      await tester.tap(
        find.byKey(const Key('receipt_review_manual_scan_button')),
      );
      await tester.pumpAndSettle();

      _fakeScannerPlatform().emitBarcode('4006381333931');
      await tester.pumpAndSettle();

      final ocrButtonAfter = tester.widget<OutlinedButton>(ocrButtonFinder);
      expect(ocrButtonAfter.onPressed, isNotNull);

      await tester.tap(ocrButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('321'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_name_field')),
        'Manual Product',
      );
      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_brand_field')),
        'Manual Brand',
      );
      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_weight_field')),
        '330',
      );

      final manualSaveButton = tester.widget<FilledButton>(
        find.byKey(const Key('receipt_review_manual_save_button')),
      );
      manualSaveButton.onPressed!.call();
      await tester.pumpAndSettle();

      expect(find.text('330 g'), findsOneWidget);

      await _confirmReviewItem(tester, 0);

      final saveButton = find.byKey(const Key('receipt_review_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedItems, isNotNull);
      expect(savedItems!.single.name, 'Manual Product');
      expect(savedItems!.single.brand, 'Manual Brand');
      expect(savedItems!.single.barcode, '4006381333931');
      expect(savedItems!.single.nutrition?.per100Kcal, 321);
    },
  );

  testWidgets('suggested candidate already shows nutrition chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'KÄSE SCHEIBEN 150G',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(id: 'gouda', name: 'Gouda', brand: 'Milbona'),
              _candidate(id: 'edamer', name: 'Edamer', brand: 'Milbona'),
            ],
            selectedGlobalFoodItemId: 'gouda',
            selectionNeedsReview: true,
            ocrName: 'KÄSE SCHEIBEN 150G',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('Gouda'), findsOneWidget);
    expect(find.textContaining('120 kcal'), findsOneWidget);
  });

  testWidgets('item preview shows unit price, quantity, and weight pills', (
    tester,
  ) async {
    final receiptDate = DateTime.parse('2026-01-05');
    const quantity = 3;
    const unitPrice = 1.5;
    const weight = '800g';

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            quantity: quantity,
            weight: weight,
            unitPrice: unitPrice,
            receiptDate: receiptDate,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final expectedUnitPrice = currency.format(unitPrice);

    expect(find.text(expectedUnitPrice), findsOneWidget);
    expect(find.text('${quantity}x'), findsOneWidget);
    expect(find.text(weight), findsOneWidget);
  });

  testWidgets(
    'receipt review uses parsed item currency when app locale is english',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          items: <InventoryItem>[
            _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              unitPrice: 1.5,
              currencyCode: 'USD',
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (_) async {},
        ),
      );

      expect(find.text('\$1.50'), findsWidgets);
      expect(find.text('€1.50'), findsNothing);
    },
  );

  testWidgets('receipt weight stays preferred over candidate weight pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'R-Hackfleisc',
              weight: '500g',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(
                id: 'off-4043362046206',
                name: 'Rinderhack',
                brand: 'Gut Ponholz',
                packageWeight: '800g',
              ),
            ],
            selectedGlobalFoodItemId: 'off-4043362046206',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('1x'), findsOneWidget);
    expect(find.text('500g'), findsOneWidget);
    expect(find.text('800g'), findsNothing);
  });

  testWidgets('preview shows confirmed weight over candidate weight', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'R-Hackfleisc',
              weight: '750g',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(
                id: 'off-4043362046206',
                name: 'Rinderhack',
                brand: 'Gut Ponholz',
                packageWeight: '800g',
              ),
            ],
            selectedGlobalFoodItemId: 'off-4043362046206',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('750g'), findsOneWidget);
    expect(find.text('800g'), findsNothing);
  });

  testWidgets('receipt metadata is shown above price overview', (tester) async {
    final receiptDate = DateTime.parse('2026-01-05');
    const storeName = 'My Store';

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            storeName: storeName,
            receiptDate: receiptDate,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final l10n = AppLocalizations.of(context)!;
    final expectedDate = DateFormat.yMd(locale).format(receiptDate);

    final storeFinder = find.text(storeName);
    final dateFinder = find.text(expectedDate);
    final priceTitleFinder = find.text(l10n.inventoryReceiptReviewPriceTitle);

    expect(storeFinder, findsOneWidget);
    expect(dateFinder, findsOneWidget);
    expect(priceTitleFinder, findsOneWidget);

    final metadataY = tester.getTopLeft(storeFinder).dy;
    final priceOverviewY = tester.getTopLeft(priceTitleFinder).dy;
    expect(metadataY, lessThan(priceOverviewY));
  });

  testWidgets(
    'edited item keeps receipt date and hides store/date editor fields',
    (tester) async {
      List<InventoryItem>? savedItems;
      final receiptDate = DateTime.parse('2026-01-05');

      await tester.pumpWidget(
        _wrap(
          items: <InventoryItem>[
            _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              weight: '500 g',
              nutrition: _testNutrition,
              receiptDate: receiptDate,
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (items) async {
            savedItems = items;
          },
        ),
      );

      await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('receipt_review_field_name')),
        'Edited item',
      );
      await tester.pumpAndSettle();

      final storeField = find.byKey(
        const Key('receipt_review_field_store_name'),
      );
      expect(storeField, findsNothing);
      expect(
        find.byKey(const Key('receipt_review_clear_receipt_date_button')),
        findsNothing,
      );
      final applyButton = find.byKey(
        const Key('receipt_review_apply_item_button'),
      );
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      await _confirmReviewItem(tester, 0);

      final saveButton = find.byKey(const Key('receipt_review_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedItems, isNotNull);
      expect(savedItems, hasLength(1));
      expect(savedItems!.single.name, 'Edited item');
      expect(savedItems!.single.receiptDate, receiptDate);
    },
  );

  testWidgets('save action is disabled when all items are review-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_save_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('save action shows progress indicator while saving', (
    tester,
  ) async {
    final saveCompleter = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) => saveCompleter.future,
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    await _confirmReviewItem(tester, 0);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.inventoryReceiptReviewSaveAction), findsNothing);

    saveCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('missing receipt weight needs explicit confirm before save', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'KÄSE SCHEIBEN',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(
                id: 'gouda',
                name: 'Gouda',
                brand: 'Milbona',
                packageWeight: '800g',
              ),
            ],
            selectedGlobalFoodItemId: 'gouda',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_save_button')),
    );
    expect(saveButton.onPressed, isNull);

    await _confirmReviewItem(tester, 0);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.weight, '800g');
    expect(savedItems!.single.initialAmount, 800);
    expect(savedItems!.single.amountUnit, InventoryAmountUnit.gram);
  });

  testWidgets('header keeps only save action visible', (tester) async {
    var saveTapCount = 0;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {
          saveTapCount++;
        },
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.inventoryReceiptReviewCancelAction), findsNothing);
    await _confirmReviewItem(tester, 0);
    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(saveTapCount, 1);
  });

  testWidgets('items section shows empty state when there are no items', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: const <InventoryItem>[],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.inventoryReceiptReviewEmpty), findsOneWidget);
  });

  testWidgets('items section renders all preview rows', (tester) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'first',
            name: 'First item',
            isDeposit: false,
            isDiscount: false,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
          _item(
            id: 'second',
            name: 'Second item',
            isDeposit: false,
            isDiscount: false,
            weight: '600 g',
            nutrition: _testNutrition,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('First item'), findsOneWidget);
    expect(find.text('Second item'), findsOneWidget);
    expect(
      find.byKey(const Key('receipt_review_edit_button_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_edit_button_1')),
      findsOneWidget,
    );
  });

  testWidgets('edit interaction updates the tapped item index only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'first',
            name: 'First item',
            isDeposit: false,
            isDiscount: false,
          ),
          _item(
            id: 'second',
            name: 'Second item',
            isDeposit: false,
            isDiscount: false,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final editButton = find.byKey(const Key('receipt_review_edit_button_1'));
    await tester.scrollUntilVisible(
      editButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(editButton.hitTestable());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_name')),
      'Edited second',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('First item'), findsOneWidget);
    expect(find.text('Edited second'), findsOneWidget);
  });

  testWidgets('invalid item number input shows inline validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_quantity')),
      'abc',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsNWidgets(2));
  });

  testWidgets('correcting number input clears inline validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final quantityField = find.byKey(
      const Key('receipt_review_field_quantity'),
    );
    await tester.enterText(quantityField, 'abc');
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsNWidgets(2));

    await tester.enterText(quantityField, '2');
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsNothing);
  });

  testWidgets('changing quantity revalidates weight error immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_quantity')),
      'abc',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_weight')),
      '500',
    );
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_quantity')),
      '2',
    );
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsOneWidget);
  });

  testWidgets('clearing prefilled brand persists as null', (tester) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            brand: 'House Brand',
            weight: '500 g',
            nutrition: _testNutrition,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final brandField = find.byKey(const Key('receipt_review_field_brand'));
    await tester.ensureVisible(brandField);
    await tester.enterText(brandField, '');
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    await _confirmReviewItem(tester, 0);

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.brand, isNull);
  });

  testWidgets('editor hides keyboard when tapping outside text field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('receipt_review_field_name'));
    await tester.showKeyboard(nameField);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    final l10n = AppLocalizations.of(tester.element(nameField))!;
    await tester.tap(find.text(l10n.inventoryReceiptReviewEditTitle));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      find.byKey(const Key('receipt_review_apply_item_button')),
      findsOneWidget,
    );
  });

  testWidgets('editor submits on keyboard done action', (tester) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('receipt_review_field_name'));
    await tester.enterText(nameField, 'Submitted from keyboard');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('receipt_review_field_name')), findsNothing);

    await _confirmReviewItem(tester, 0);

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.name, 'Submitted from keyboard');
  });

  testWidgets('weight without unit shows inline validation', (tester) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_weight')),
      '500',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsOneWidget);
  });

  testWidgets('invalid discounts input shows inline validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'coupon',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      'abc',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Use JSON or key=value pairs.'), findsOneWidget);
  });

  testWidgets('discount row keys stay stable after removing first row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            discounts: const <String, double>{
              'Coupon': -1.20,
              'Loyalty': -0.50,
            },
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_name_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_discount_name_1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('receipt_review_discount_remove_0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_name_0')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('receipt_review_discount_name_1')),
      findsOneWidget,
    );
  });

  testWidgets('discount lines merge into previous item and remain visible', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
          _item(
            id: 'discount',
            name: 'Coupon',
            isDeposit: false,
            isDiscount: true,
            unitPrice: -1.20,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_edit_button_0')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('receipt_review_edit_button_1')), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );
    expect(find.textContaining('Coupon'), findsOneWidget);

    await _confirmReviewItem(tester, 0);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.discounts['Coupon'], -1.20);
  });

  testWidgets('rabatt row without isDiscount flag merges into previous item', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'mandarine',
            name: 'Mandarinen',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 2.00,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 1.50,
            weight: '600 g',
            nutrition: _testNutrition,
          ),
          _item(
            id: 'rabatt',
            name: 'Rabatt',
            isDeposit: false,
            isDiscount: false,
            unitPrice: -0.50,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_edit_button_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_edit_button_1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('receipt_review_edit_button_2')), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_discount_row_1_0')),
      findsOneWidget,
    );
    expect(find.textContaining('Rabatt'), findsOneWidget);

    await _confirmReviewItem(tester, 0);
    await _confirmReviewItem(tester, 1);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(2));
    expect(savedItems![1].discounts['Rabatt'], -0.50);
  });

  testWidgets('rabatt row merges even when mapped as deposit', (tester) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'mandarine',
            name: 'Mandarinen',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 2.00,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 1.50,
            weight: '600 g',
            nutrition: _testNutrition,
          ),
          _item(
            id: 'rabatt',
            name: 'Rabatt',
            isDeposit: true,
            isDiscount: false,
            unitPrice: -0.50,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_row_1_0')),
      findsOneWidget,
    );

    await _confirmReviewItem(tester, 0);
    await _confirmReviewItem(tester, 1);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(2));
    expect(savedItems![1].discounts['Rabatt'], -0.50);
  });

  testWidgets('leergut row does not merge into previous item discount list', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'mandarine',
            name: 'Mandarinen',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 2.00,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 1.50,
            weight: '600 g',
            nutrition: _testNutrition,
          ),
          _item(
            id: 'leergut',
            name: 'Leergut',
            isDeposit: false,
            isDiscount: false,
            unitPrice: -0.50,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_row_1_0')),
      findsNothing,
    );

    await _confirmReviewItem(tester, 0);
    await _confirmReviewItem(tester, 1);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(3));
    expect(savedItems![1].discounts, isEmpty);
    expect(savedItems![2].isDeposit, isTrue);
    expect(savedItems![2].isDiscount, isFalse);
  });

  testWidgets('added discount entries appear as gray rows below item', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'Loyalty',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '-0.50',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );
    expect(find.textContaining('Loyalty'), findsOneWidget);

    await _confirmReviewItem(tester, 0);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.discounts, <String, double>{'Loyalty': -0.5});
  });

  testWidgets('unnamed discount row avoids duplicated discounts label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            discounts: const <String, double>{'': -0.5},
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;
    final duplicatedLabel =
        '${l10n.inventoryReceiptReviewFieldDiscounts}: '
        '${l10n.inventoryReceiptReviewFieldDiscounts}';

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );
    expect(find.textContaining(duplicatedLabel), findsNothing);
  });

  testWidgets('positive discount input is normalized to negative amount', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            weight: '500 g',
            nutrition: _testNutrition,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'Coupon',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '1.50',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    await _confirmReviewItem(tester, 0);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.discounts['Coupon'], -1.5);
  });

  testWidgets('clearing discount in editor removes discount row from list', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            weight: '500 g',
            nutrition: _testNutrition,
            discounts: const <String, double>{'Rabatt': -0.50},
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      '',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsNothing,
    );

    await _confirmReviewItem(tester, 0);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.discounts, isEmpty);
  });

  testWidgets(
    'added discount on first item is rendered between first and second',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          items: <InventoryItem>[
            _item(
              id: 'mandarine',
              name: 'Mandarinen',
              isDeposit: false,
              isDiscount: false,
            ),
            _item(
              id: 'gurke',
              name: 'Gurken',
              isDeposit: false,
              isDiscount: false,
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (_) async {},
        ),
      );

      await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('receipt_review_discount_name_0')),
        'Coupon',
      );
      await tester.enterText(
        find.byKey(const Key('receipt_review_discount_amount_0')),
        '-0.50',
      );
      await tester.pumpAndSettle();

      final applyButton = find.byKey(
        const Key('receipt_review_apply_item_button'),
      );
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      final discountRow = find.byKey(
        const Key('receipt_review_discount_row_0_0'),
      );
      expect(discountRow, findsOneWidget);

      final firstItemY = tester.getTopLeft(find.text('Mandarinen')).dy;
      final discountRowY = tester.getTopLeft(discountRow).dy;
      final secondItemY = tester.getTopLeft(find.text('Gurken')).dy;
      expect(firstItemY, lessThan(discountRowY));
      expect(discountRowY, lessThan(secondItemY));
    },
  );

  testWidgets('weight without suffix saves when gram fallback is selected', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            nutrition: _testNutrition,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_weight')),
      '500',
    );
    await tester.pumpAndSettle();

    final unitDropdown = find.byKey(
      const Key('receipt_review_field_weight_unit_fallback'),
    );
    await tester.ensureVisible(unitDropdown);
    await tester.tap(unitDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gram (g)').last);
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsNothing);

    await _confirmReviewItem(tester, 0);

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.initialAmount, 500);
    expect(savedItems!.single.currentAmount, 500);
    expect(savedItems!.single.amountUnit, InventoryAmountUnit.gram);
  });
}
