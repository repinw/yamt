import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/data/receipt_to_fridge_item_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';

class _FakeReceiptInputRepository implements ReceiptInputRepository {
  _FakeReceiptInputRepository({required this.pickFiles});

  final Future<ReceiptInputBatchResult> Function() pickFiles;

  @override
  Future<ReceiptInputResult> pickFromCamera() async {
    return const ReceiptInputResult.canceled();
  }

  @override
  Future<ReceiptInputResult> pickFromFile() async {
    return const ReceiptInputResult.canceled();
  }

  @override
  Future<ReceiptInputBatchResult> pickFromFiles() {
    return pickFiles();
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

ReceiptInputSelection _selectionWithName(String name) {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: name,
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

FridgeItem _fridgeItem({required String id}) {
  return FridgeItem(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-24T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.99,
  );
}

void main() {
  test('runFileBatch sets inputCanceled when picker is dismissed', () async {
    final container = ProviderContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(
          _FakeReceiptInputRepository(
            pickFiles: () async => const ReceiptInputBatchResult.canceled(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(receiptBatchFlowControllerProvider.notifier)
        .runFileBatch();
    final state = container.read(receiptBatchFlowControllerProvider);

    expect(state.status, ReceiptBatchFlowStatus.inputCanceled);
    expect(state.progress.totalCount, 0);
  });

  test(
    'runFileBatch processes selections and exposes reviewable index',
    () async {
      final analysisOrder = <String>[];
      final container = ProviderContainer(
        overrides: [
          receiptInputRepositoryProvider.overrideWithValue(
            _FakeReceiptInputRepository(
              pickFiles: () async => ReceiptInputBatchResult.selected(
                selections: <ReceiptInputSelection>[
                  _selectionWithName('a.jpg'),
                  _selectionWithName('b.jpg'),
                ],
              ),
            ),
          ),
          receiptAnalysisRepositoryProvider.overrideWithValue(
            _FakeReceiptAnalysisRepository(
              onAnalyzeSelection: (selection) async {
                analysisOrder.add(selection.name);
                if (selection.name == 'a.jpg') {
                  return const ReceiptAnalysisResult.succeeded(
                    rawResponse: '{"i":[{"n":"A"}]}',
                    extraction: ReceiptAnalysisExtraction(
                      root: <String, dynamic>{},
                      items: <ReceiptAnalysisItem>[
                        ReceiptAnalysisItem(
                          name: 'A',
                          rawPayload: <String, dynamic>{'n': 'A'},
                        ),
                      ],
                    ),
                  );
                }
                return const ReceiptAnalysisResult.failed(
                  errorCode: ReceiptAnalysisErrorCodes.aiRequestFailed,
                );
              },
            ),
          ),
          receiptToFridgeItemMapperProvider.overrideWithValue(
            _FakeReceiptToFridgeItemMapper(
              onMap: (_) => <FridgeItem>[_fridgeItem(id: 'mapped-a')],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(receiptBatchFlowControllerProvider.notifier)
          .runFileBatch();
      final state = container.read(receiptBatchFlowControllerProvider);

      expect(state.status, ReceiptBatchFlowStatus.completed);
      expect(state.progress.totalCount, 2);
      expect(state.progress.processedCount, 2);
      expect(state.progress.succeededCount, 1);
      expect(state.progress.failedCount, 1);
      expect(state.reviewableIndices, <int>{0});
      expect(state.pendingAutoReviewIndex, 0);
      expect(state.mappedItemsForIndex(0), hasLength(1));
      expect(analysisOrder, <String>['a.jpg', 'b.jpg']);
    },
  );

  test('runFileBatch sets inputFailed for picker failure', () async {
    final container = ProviderContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(
          _FakeReceiptInputRepository(
            pickFiles: () async => const ReceiptInputBatchResult.failed(
              errorCode: ReceiptInputErrorCodes.filePickFailed,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(receiptBatchFlowControllerProvider.notifier)
        .runFileBatch();
    final state = container.read(receiptBatchFlowControllerProvider);

    expect(state.status, ReceiptBatchFlowStatus.inputFailed);
    expect(state.errorCode, ReceiptInputErrorCodes.filePickFailed);
  });

  test(
    'runFileBatch sets analysisFailed when no mapped items are produced',
    () async {
      final container = ProviderContainer(
        overrides: [
          receiptInputRepositoryProvider.overrideWithValue(
            _FakeReceiptInputRepository(
              pickFiles: () async => ReceiptInputBatchResult.selected(
                selections: <ReceiptInputSelection>[
                  _selectionWithName('a.jpg'),
                ],
              ),
            ),
          ),
          receiptAnalysisRepositoryProvider.overrideWithValue(
            _FakeReceiptAnalysisRepository(
              onAnalyzeSelection: (_) async =>
                  const ReceiptAnalysisResult.failed(
                    errorCode: ReceiptAnalysisErrorCodes.aiRequestFailed,
                  ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(receiptBatchFlowControllerProvider.notifier)
          .runFileBatch();
      final state = container.read(receiptBatchFlowControllerProvider);

      expect(state.status, ReceiptBatchFlowStatus.analysisFailed);
    },
  );

  test('startReview/finishReview move review state into controller', () async {
    final container = ProviderContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(
          _FakeReceiptInputRepository(
            pickFiles: () async => ReceiptInputBatchResult.selected(
              selections: <ReceiptInputSelection>[_selectionWithName('a.jpg')],
            ),
          ),
        ),
        receiptAnalysisRepositoryProvider.overrideWithValue(
          _FakeReceiptAnalysisRepository(
            onAnalyzeSelection: (_) async =>
                const ReceiptAnalysisResult.succeeded(
                  rawResponse: '{"i":[{"n":"A"}]}',
                  extraction: ReceiptAnalysisExtraction(
                    root: <String, dynamic>{},
                    items: <ReceiptAnalysisItem>[
                      ReceiptAnalysisItem(
                        name: 'A',
                        rawPayload: <String, dynamic>{'n': 'A'},
                      ),
                    ],
                  ),
                ),
          ),
        ),
        receiptToFridgeItemMapperProvider.overrideWithValue(
          _FakeReceiptToFridgeItemMapper(
            onMap: (_) => <FridgeItem>[_fridgeItem(id: 'mapped-a')],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      receiptBatchFlowControllerProvider.notifier,
    );
    await controller.runFileBatch();

    expect(controller.startReview(0), isTrue);
    expect(controller.startReview(0), isFalse);
    expect(
      container.read(receiptBatchFlowControllerProvider).activeReviewIndex,
      0,
    );

    controller.finishReview(index: 0, saved: true);
    final state = container.read(receiptBatchFlowControllerProvider);
    expect(state.activeReviewIndex, isNull);
    expect(state.reviewedIndices, <int>{0});
  });
}
