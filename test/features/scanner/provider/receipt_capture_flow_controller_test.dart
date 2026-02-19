import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/data/receipt_to_fridge_item_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
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

class _FakeReceiptToFridgeItemMapper implements ReceiptToFridgeItemMapper {
  _FakeReceiptToFridgeItemMapper({required this.onMap});

  final List<FridgeItem> Function(ReceiptAnalysisExtraction extraction) onMap;

  @override
  List<FridgeItem> map(ReceiptAnalysisExtraction extraction) {
    return onMap(extraction);
  }
}

class _FakeFridgeItemRepository implements FridgeItemRepository {
  _FakeFridgeItemRepository({this.onAppendAll});

  final Future<bool> Function(List<FridgeItem> items)? onAppendAll;

  List<FridgeItem> appendedItems = const <FridgeItem>[];

  @override
  Future<bool> appendAll(List<FridgeItem> items) async {
    appendedItems = items;
    final callback = onAppendAll;
    if (callback != null) {
      return callback(items);
    }
    return true;
  }

  @override
  Future<List<FridgeItem>> readAll() async {
    return const <FridgeItem>[];
  }

  @override
  Future<bool> saveAll(List<FridgeItem> items) async {
    return true;
  }
}

ReceiptInputSelection _selection() {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: 'receipt.jpg',
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

FridgeItem _fridgeItem({
  required String id,
  required bool isDeposit,
  required bool isDiscount,
}) {
  return FridgeItem(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.99,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
  );
}

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

  test(
    'successful analysis maps to completed status with extraction',
    () async {
      final selection = _selection();
      final mapper = _FakeReceiptToFridgeItemMapper(
        onMap: (_) => <FridgeItem>[
          _fridgeItem(id: 'food', isDeposit: false, isDiscount: false),
          _fridgeItem(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
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
          receiptToFridgeItemMapperProvider.overrideWithValue(mapper),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(receiptCaptureFlowControllerProvider.notifier)
          .run(source: ReceiptInputSource.file);

      expect(result.status, ReceiptCaptureFlowStatus.completed);
      expect(result.extraction, isNotNull);
      expect(result.extraction!.items.single.name, 'Milk');
      expect(result.mappedItems, hasLength(2));
      expect(result.mappedItems!.first.id, 'food');
      expect(
        container.read(receiptCaptureFlowControllerProvider).value,
        result,
      );
    },
  );

  test('persistReviewedItems saves only non-review-only items', () async {
    final fridgeRepository = _FakeFridgeItemRepository();
    final container = ProviderContainer(
      overrides: [
        fridgeItemRepositoryProvider.overrideWithValue(fridgeRepository),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      receiptCaptureFlowControllerProvider.notifier,
    );
    final saved = await controller.persistReviewedItems(<FridgeItem>[
      _fridgeItem(id: 'food', isDeposit: false, isDiscount: false),
      _fridgeItem(id: 'deposit', isDeposit: true, isDiscount: false),
      _fridgeItem(id: 'discount', isDeposit: false, isDiscount: true),
    ]);

    expect(saved, isTrue);
    expect(fridgeRepository.appendedItems, hasLength(1));
    expect(fridgeRepository.appendedItems.single.id, 'food');
  });

  test(
    'persistReviewedItems returns false when repository save fails',
    () async {
      final fridgeRepository = _FakeFridgeItemRepository(
        onAppendAll: (_) async => false,
      );
      final container = ProviderContainer(
        overrides: [
          fridgeItemRepositoryProvider.overrideWithValue(fridgeRepository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        receiptCaptureFlowControllerProvider.notifier,
      );
      final saved = await controller.persistReviewedItems(<FridgeItem>[
        _fridgeItem(id: 'food', isDeposit: false, isDiscount: false),
      ]);

      expect(saved, isFalse);
    },
  );
}
