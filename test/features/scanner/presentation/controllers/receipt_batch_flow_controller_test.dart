import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
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
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_batch_flow_controller.dart';

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

class _FakeReceiptReviewResolutionService
    extends ReceiptReviewResolutionService {
  _FakeReceiptReviewResolutionService({required this.onPrepareDrafts})
    : super(
        mapper: _UnsupportedMapper(),
        matcher: _UnsupportedMatcher(),
        globalFoodItemRepository: _UnsupportedGlobalRepository(),
        inventoryItemRepository: _UnsupportedInventoryRepository(),
      );

  final FutureOr<List<ReceiptReviewItemDraft>> Function(
    ReceiptAnalysisExtraction extraction,
  )
  onPrepareDrafts;

  @override
  Future<List<ReceiptReviewItemDraft>> prepareDrafts(
    ReceiptAnalysisExtraction extraction,
  ) async {
    return onPrepareDrafts(extraction);
  }
}

class _UnsupportedMapper implements ReceiptToReviewItemDraftMapper {
  @override
  List<ReceiptReviewItemDraft> map(ReceiptAnalysisExtraction extraction) {
    throw UnimplementedError();
  }
}

class _UnsupportedMatcher extends GlobalFoodItemMatcher {
  _UnsupportedMatcher();
}

class _UnsupportedGlobalRepository implements GlobalFoodItemRepository {
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

class _UnsupportedInventoryRepository implements InventoryItemRepository {
  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

ReceiptInputSelection _selectionWithName(String name) {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: name,
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

ReceiptReviewItemDraft _reviewDraft({required String id}) {
  return ReceiptReviewItemDraft(
    item: InventoryItem.create(
      id: id,
      name: 'Milk',
      entryDate: DateTime.parse('2026-02-24T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      unitPrice: 1.99,
    ),
  );
}

@Dependencies([ReceiptBatchFlowController])
void main() {
  test(
    'runFileBatch reuses in-flight operation for concurrent calls',
    () async {
      final pickCompleter = Completer<ReceiptInputBatchResult>();
      var pickCalls = 0;
      final container = ProviderContainer(
        overrides: [
          receiptInputRepositoryProvider.overrideWithValue(
            _FakeReceiptInputRepository(
              pickFiles: () {
                pickCalls += 1;
                return pickCompleter.future;
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        receiptBatchFlowControllerProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final controller = container.read(
        receiptBatchFlowControllerProvider.notifier,
      );
      final first = controller.runFileBatch();
      final second = controller.runFileBatch();

      await Future<void>.delayed(Duration.zero);
      expect(pickCalls, 1);

      pickCompleter.complete(const ReceiptInputBatchResult.canceled());
      await Future.wait<void>(<Future<void>>[first, second]);

      final state = container.read(receiptBatchFlowControllerProvider);
      expect(state.status, ReceiptBatchFlowStatus.inputCanceled);
      expect(pickCalls, 1);
    },
  );

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
    'runSelections processes provided shared selections without picker',
    () async {
      final analysisOrder = <String>[];
      final container = ProviderContainer(
        overrides: [
          receiptAnalysisRepositoryProvider.overrideWithValue(
            _FakeReceiptAnalysisRepository(
              onAnalyzeSelection: (selection) async {
                analysisOrder.add(selection.name);
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
              },
            ),
          ),
          receiptReviewResolutionServiceProvider.overrideWithValue(
            _FakeReceiptReviewResolutionService(
              onPrepareDrafts: (_) async => <ReceiptReviewItemDraft>[
                _reviewDraft(id: 'mapped-a'),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(receiptBatchFlowControllerProvider.notifier)
          .runSelections(<ReceiptInputSelection>[
            _selectionWithName('shared-a.jpg'),
            _selectionWithName('shared-b.jpg'),
          ]);
      final state = container.read(receiptBatchFlowControllerProvider);

      expect(state.status, ReceiptBatchFlowStatus.completed);
      expect(state.reviewableIndices, <int>{0, 1});
      expect(analysisOrder, <String>['shared-a.jpg', 'shared-b.jpg']);
    },
  );

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
          receiptReviewResolutionServiceProvider.overrideWithValue(
            _FakeReceiptReviewResolutionService(
              onPrepareDrafts: (_) async => <ReceiptReviewItemDraft>[
                _reviewDraft(id: 'mapped-a'),
              ],
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
      expect(state.reviewDraftsForIndex(0), hasLength(1));
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
        receiptReviewResolutionServiceProvider.overrideWithValue(
          _FakeReceiptReviewResolutionService(
            onPrepareDrafts: (_) async => <ReceiptReviewItemDraft>[
              _reviewDraft(id: 'mapped-a'),
            ],
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
