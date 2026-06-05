import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/application/'
    'receipt_review_resolution_service.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/data/receipt_to_review_item_draft_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/inventory/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';

class _FakeReceiptInputRepository implements ReceiptInputRepository {
  _FakeReceiptInputRepository({this.pickFile});

  final Future<ReceiptInputResult> Function()? pickFile;

  @override
  Future<ReceiptInputResult> pickFromCamera() {
    return Future<ReceiptInputResult>.value(
      const ReceiptInputResult.canceled(),
    );
  }

  @override
  Future<ReceiptInputResult> pickFromFile() {
    final callback = pickFile;
    if (callback != null) {
      return callback();
    }
    return Future<ReceiptInputResult>.value(
      const ReceiptInputResult.canceled(),
    );
  }

  @override
  Future<ReceiptInputBatchResult> pickFromFiles() {
    return Future<ReceiptInputBatchResult>.value(
      const ReceiptInputBatchResult.canceled(),
    );
  }
}

class _FakeReceiptAnalysisRepository implements ReceiptAnalysisRepository {
  _FakeReceiptAnalysisRepository({required this.onAnalyzeSelection});

  final Future<ReceiptAnalysisResult> Function(ReceiptInputSelection selection)
  onAnalyzeSelection;

  @override
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  ) {
    return onAnalyzeSelection(selection);
  }
}

class _FakeReceiptReviewResolutionService
    extends ReceiptReviewResolutionService {
  _FakeReceiptReviewResolutionService({
    required this.onPrepareDrafts,
    required this.onPersistReviewedItems,
  }) : super(
         mapper: _UnsupportedReceiptToReviewItemDraftMapper(),
         globalFoodItemRepository: _UnsupportedGlobalFoodItemRepository(),
         inventoryItemRepository: _UnsupportedInventoryItemRepository(),
       );

  final FutureOr<List<ReceiptReviewItemDraft>> Function(
    ReceiptAnalysisExtraction extraction,
  )
  onPrepareDrafts;
  final FutureOr<ReceiptReviewPersistResult> Function(
    List<ReceiptReviewItemDraft> reviewedItems,
  )
  onPersistReviewedItems;

  @override
  Future<List<ReceiptReviewItemDraft>> prepareDrafts(
    ReceiptAnalysisExtraction extraction,
  ) async {
    return onPrepareDrafts(extraction);
  }

  @override
  Future<ReceiptReviewPersistResult> persistReviewedItems(
    List<ReceiptReviewItemDraft> reviewedItems,
  ) async {
    return onPersistReviewedItems(reviewedItems);
  }
}

class _UnsupportedReceiptToReviewItemDraftMapper
    implements ReceiptToReviewItemDraftMapper {
  @override
  List<ReceiptReviewItemDraft> map(ReceiptAnalysisExtraction extraction) {
    throw UnimplementedError();
  }
}

class _UnsupportedGlobalFoodItemRepository implements GlobalFoodItemRepository {
  @override
  Stream<List<GlobalFoodItem>> watchAll() async* {
    yield const <GlobalFoodItem>[];
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async {
    return const <GlobalFoodItem>[];
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
  Future<bool> saveAll(List<GlobalFoodItem> items) async => true;

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async => true;
}

class _UnsupportedInventoryItemRepository implements InventoryItemRepository {
  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
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
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }
}

ReceiptInputSelection _selection() {
  return _selectionWithName('receipt.jpg');
}

ReceiptInputSelection _selectionWithName(String name) {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: name,
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

InventoryItem _inventoryItem({
  required String id,
  required bool isDeposit,
  required bool isDiscount,
}) {
  return InventoryItem.create(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    unitPrice: 1.99,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
  );
}

ReceiptReviewItemDraft _draft({
  required String id,
  required bool isDeposit,
  required bool isDiscount,
}) {
  return ReceiptReviewItemDraft(
    item: _inventoryItem(id: id, isDeposit: isDeposit, isDiscount: isDiscount),
  );
}

@Dependencies([ReceiptCaptureFlowController])
void main() {
  test('camera unsupported short-circuits with unsupported status', () async {
    final container = ProviderContainer(
      overrides: [
        receiptCameraSupportedProvider.overrideWith((ref) => false),
        receiptInputRepositoryProvider.overrideWithValue(
          _FakeReceiptInputRepository(),
        ),
        receiptAnalysisRepositoryProvider.overrideWithValue(
          _FakeReceiptAnalysisRepository(
            onAnalyzeSelection: (_) async => const ReceiptAnalysisResult.failed(
              errorCode: ReceiptAnalysisErrorCodes.unexpected,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptCaptureFlowControllerProvider.notifier)
        .run(source: ReceiptInputSource.camera);

    expect(result.status, ReceiptCaptureFlowStatus.inputUnsupported);
    expect(result.errorCode, ReceiptInputErrorCodes.cameraNotSupported);
    expect(container.read(receiptCaptureFlowControllerProvider).value, result);
  });

  test('canceled input maps to inputCanceled status', () async {
    final inputRepository = _FakeReceiptInputRepository(
      pickFile: () async => const ReceiptInputResult.canceled(),
    );
    final analysisRepository = _FakeReceiptAnalysisRepository(
      onAnalyzeSelection: (_) async => const ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.unexpected,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        receiptCameraSupportedProvider.overrideWith((ref) => true),
        receiptInputRepositoryProvider.overrideWithValue(inputRepository),
        receiptAnalysisRepositoryProvider.overrideWithValue(analysisRepository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptCaptureFlowControllerProvider.notifier)
        .run(source: ReceiptInputSource.file);

    expect(result.status, ReceiptCaptureFlowStatus.inputCanceled);
    expect(container.read(receiptCaptureFlowControllerProvider).value, result);
  });

  test('input failure maps to inputFailed status', () async {
    final inputRepository = _FakeReceiptInputRepository(
      pickFile: () async => const ReceiptInputResult.failed(
        errorCode: ReceiptInputErrorCodes.filePickFailed,
      ),
    );
    final analysisRepository = _FakeReceiptAnalysisRepository(
      onAnalyzeSelection: (_) async => const ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.unexpected,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        receiptCameraSupportedProvider.overrideWith((ref) => true),
        receiptInputRepositoryProvider.overrideWithValue(inputRepository),
        receiptAnalysisRepositoryProvider.overrideWithValue(analysisRepository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptCaptureFlowControllerProvider.notifier)
        .run(source: ReceiptInputSource.file);

    expect(result.status, ReceiptCaptureFlowStatus.inputFailed);
    expect(result.errorCode, ReceiptInputErrorCodes.filePickFailed);
  });

  test('analysis failure maps to analysisFailed status', () async {
    final selection = _selection();
    final inputRepository = _FakeReceiptInputRepository(
      pickFile: () async => ReceiptInputResult.selected(selection: selection),
    );
    final analysisRepository = _FakeReceiptAnalysisRepository(
      onAnalyzeSelection: (_) async => const ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.aiRequestFailed,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        receiptCameraSupportedProvider.overrideWith((ref) => true),
        receiptInputRepositoryProvider.overrideWithValue(inputRepository),
        receiptAnalysisRepositoryProvider.overrideWithValue(analysisRepository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptCaptureFlowControllerProvider.notifier)
        .run(source: ReceiptInputSource.file);

    expect(result.status, ReceiptCaptureFlowStatus.analysisFailed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.aiRequestFailed);
  });

  test('run reuses in-flight operation for concurrent calls', () async {
    final selection = _selection();
    final pickCompleter = Completer<ReceiptInputResult>();
    final analysisCompleter = Completer<ReceiptAnalysisResult>();
    var pickCalls = 0;
    var analysisCalls = 0;

    final inputRepository = _FakeReceiptInputRepository(
      pickFile: () {
        pickCalls += 1;
        return pickCompleter.future;
      },
    );
    final analysisRepository = _FakeReceiptAnalysisRepository(
      onAnalyzeSelection: (_) {
        analysisCalls += 1;
        return analysisCompleter.future;
      },
    );

    final container = ProviderContainer(
      overrides: [
        receiptCameraSupportedProvider.overrideWith((ref) => true),
        receiptInputRepositoryProvider.overrideWithValue(inputRepository),
        receiptAnalysisRepositoryProvider.overrideWithValue(analysisRepository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      receiptCaptureFlowControllerProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final controller = container.read(
      receiptCaptureFlowControllerProvider.notifier,
    );
    final first = controller.run(source: ReceiptInputSource.file);
    final second = controller.run(source: ReceiptInputSource.file);

    await Future<void>.delayed(Duration.zero);
    expect(pickCalls, 1);

    pickCompleter.complete(ReceiptInputResult.selected(selection: selection));

    analysisCompleter.complete(
      const ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.aiRequestFailed,
      ),
    );

    final firstResult = await first;
    final secondResult = await second;
    expect(firstResult.status, ReceiptCaptureFlowStatus.analysisFailed);
    expect(secondResult.status, ReceiptCaptureFlowStatus.analysisFailed);
    expect(pickCalls, 1);
    expect(analysisCalls, 1);
  });

  test(
    'runSelection analyzes a provided shared selection without picker',
    () async {
      final analyzedSelections = <ReceiptInputSelection>[];
      final container = ProviderContainer(
        overrides: [
          receiptAnalysisRepositoryProvider.overrideWithValue(
            _FakeReceiptAnalysisRepository(
              onAnalyzeSelection: (selection) async {
                analyzedSelections.add(selection);
                return const ReceiptAnalysisResult.succeeded(
                  rawResponse: '{"i":[{"n":"Milk"}]}',
                  extraction: ReceiptAnalysisExtraction(
                    root: <String, dynamic>{},
                    items: <ReceiptAnalysisItem>[
                      ReceiptAnalysisItem(
                        name: 'Milk',
                        rawPayload: <String, dynamic>{'n': 'Milk'},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          receiptReviewResolutionServiceProvider.overrideWithValue(
            _FakeReceiptReviewResolutionService(
              onPrepareDrafts: (_) async => <ReceiptReviewItemDraft>[
                _draft(id: 'food', isDeposit: false, isDiscount: false),
              ],
              onPersistReviewedItems: (_) async =>
                  const ReceiptReviewPersistResult(
                    saved: true,
                    inventoryItems: <InventoryItem>[],
                  ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        receiptCaptureFlowControllerProvider.notifier,
      );
      final selection = _selectionWithName('shared-receipt.jpg');
      final result = await controller.runSelection(selection: selection);

      expect(result.status, ReceiptCaptureFlowStatus.completed);
      expect(analyzedSelections, <ReceiptInputSelection>[selection]);
      expect(result.reviewDrafts, hasLength(1));
      expect(
        container.read(receiptCaptureFlowControllerProvider).value,
        result,
      );
    },
  );

  test(
    'successful analysis maps to completed status with extraction',
    () async {
      final selection = _selection();
      final resolutionService = _FakeReceiptReviewResolutionService(
        onPrepareDrafts: (_) async => <ReceiptReviewItemDraft>[
          _draft(id: 'food', isDeposit: false, isDiscount: false),
          _draft(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
        onPersistReviewedItems: (_) async => const ReceiptReviewPersistResult(
          saved: true,
          inventoryItems: <InventoryItem>[],
        ),
      );
      final inputRepository = _FakeReceiptInputRepository(
        pickFile: () async => ReceiptInputResult.selected(selection: selection),
      );
      final analysisRepository = _FakeReceiptAnalysisRepository(
        onAnalyzeSelection: (_) async => const ReceiptAnalysisResult.succeeded(
          rawResponse: '{"i":[{"n":"Milk"}]}',
          extraction: ReceiptAnalysisExtraction(
            root: <String, dynamic>{},
            items: <ReceiptAnalysisItem>[
              ReceiptAnalysisItem(
                name: 'Milk',
                rawPayload: <String, dynamic>{'n': 'Milk'},
              ),
            ],
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          receiptCameraSupportedProvider.overrideWith((ref) => true),
          receiptInputRepositoryProvider.overrideWithValue(inputRepository),
          receiptAnalysisRepositoryProvider.overrideWithValue(
            analysisRepository,
          ),
          receiptReviewResolutionServiceProvider.overrideWithValue(
            resolutionService,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(receiptCaptureFlowControllerProvider.notifier)
          .run(source: ReceiptInputSource.file);

      expect(result.status, ReceiptCaptureFlowStatus.completed);
      expect(result.extraction, isNotNull);
      expect(result.extraction!.items.single.name, 'Milk');
      expect(result.reviewDrafts, hasLength(2));
      expect(result.reviewDrafts!.first.item.id, 'food');
      expect(
        container.read(receiptCaptureFlowControllerProvider).value,
        result,
      );
    },
  );

  test('persistReviewedItems saves only non-review-only items', () async {
    List<ReceiptReviewItemDraft>? persistedItems;
    final resolutionService = _FakeReceiptReviewResolutionService(
      onPrepareDrafts: (_) async => const <ReceiptReviewItemDraft>[],
      onPersistReviewedItems: (reviewedItems) async {
        persistedItems = reviewedItems;
        return ReceiptReviewPersistResult(
          saved: true,
          inventoryItems: <InventoryItem>[reviewedItems.first.item],
        );
      },
    );
    final container = ProviderContainer(
      overrides: [
        receiptReviewResolutionServiceProvider.overrideWithValue(
          resolutionService,
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      receiptCaptureFlowControllerProvider.notifier,
    );
    final saved = await controller.persistReviewedItems(
      <ReceiptReviewItemDraft>[
        _draft(id: 'food', isDeposit: false, isDiscount: false),
        _draft(id: 'deposit', isDeposit: true, isDiscount: false),
        _draft(id: 'discount', isDeposit: false, isDiscount: true),
      ],
    );

    expect(saved, isTrue);
    expect(persistedItems, hasLength(3));
    expect(persistedItems!.first.item.id, 'food');
  });

  test(
    'persistReviewedItems returns false when repository save fails',
    () async {
      final resolutionService = _FakeReceiptReviewResolutionService(
        onPrepareDrafts: (_) async => const <ReceiptReviewItemDraft>[],
        onPersistReviewedItems: (_) async => const ReceiptReviewPersistResult(
          saved: false,
          inventoryItems: <InventoryItem>[],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          receiptReviewResolutionServiceProvider.overrideWithValue(
            resolutionService,
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        receiptCaptureFlowControllerProvider.notifier,
      );
      final saved = await controller.persistReviewedItems(
        <ReceiptReviewItemDraft>[
          _draft(id: 'food', isDeposit: false, isDiscount: false),
        ],
      );

      expect(saved, isFalse);
    },
  );
}
