import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/data/receipt_to_fridge_item_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

part 'receipt_batch_flow_controller.g.dart';

@riverpod
class ReceiptBatchFlowController extends _$ReceiptBatchFlowController {
  @override
  ReceiptBatchFlowState build() {
    return const ReceiptBatchFlowState();
  }

  void reset() {
    state = const ReceiptBatchFlowState();
  }

  void markReviewed(int index) {
    state = state.copyWith(
      reviewedIndices: <int>{...state.reviewedIndices, index},
    );
  }

  void consumePendingAutoReview() {
    state = state.copyWith(clearPendingAutoReview: true);
  }

  Future<void> runFileBatch() async {
    state = const ReceiptBatchFlowState(status: ReceiptBatchFlowStatus.running);

    final inputRepository = ref.read(receiptInputRepositoryProvider);
    final inputResult = await inputRepository.pickFromFiles();
    if (!ref.mounted) {
      return;
    }

    switch (inputResult.status) {
      case ReceiptInputBatchStatus.selected:
        await _runSelectedBatch(inputResult.selections);
      case ReceiptInputBatchStatus.canceled:
        state = state.copyWith(status: ReceiptBatchFlowStatus.inputCanceled);
      case ReceiptInputBatchStatus.failed:
        final errorCode =
            inputResult.errorCode ?? ReceiptInputErrorCodes.filePickUnexpected;
        state = state.copyWith(
          status: ReceiptBatchFlowStatus.inputFailed,
          errorCode: errorCode,
          clearErrorCode: false,
        );
    }
  }

  Future<void> _runSelectedBatch(List<ReceiptInputSelection> selections) async {
    var progress = _queuedBatchProgress(selections);
    var mappedItemsByIndex = <int, List<FridgeItem>>{};
    var reviewableIndices = <int>{};

    state = state.copyWith(
      status: ReceiptBatchFlowStatus.running,
      progress: progress,
      reviewableIndices: reviewableIndices,
      reviewedIndices: <int>{},
      mappedItemsByIndex: mappedItemsByIndex,
      clearPendingAutoReview: true,
      autoReviewDispatched: false,
      clearErrorCode: true,
    );

    for (var index = 0; index < selections.length; index++) {
      progress = _updateBatchItem(
        progress: progress,
        index: index,
        status: ReceiptBatchItemStatus.processing,
        clearErrorCode: true,
      );
      state = state.copyWith(progress: progress);

      final analysis = await _analyzeSelection(selections[index]);
      if (!ref.mounted) {
        return;
      }

      if (analysis.errorCode == null) {
        mappedItemsByIndex = <int, List<FridgeItem>>{
          ...mappedItemsByIndex,
          index: analysis.mappedItems,
        };
        reviewableIndices = <int>{...reviewableIndices, index};
        progress = _updateBatchItem(
          progress: progress,
          index: index,
          status: ReceiptBatchItemStatus.succeeded,
          mappedItemCount: analysis.mappedItems.length,
          clearErrorCode: true,
        );

        final shouldDispatchAutoReview = !state.autoReviewDispatched;
        state = state.copyWith(
          progress: progress,
          mappedItemsByIndex: mappedItemsByIndex,
          reviewableIndices: reviewableIndices,
          pendingAutoReviewIndex: shouldDispatchAutoReview ? index : null,
          clearPendingAutoReview: !shouldDispatchAutoReview,
          autoReviewDispatched:
              state.autoReviewDispatched || shouldDispatchAutoReview,
        );
      } else {
        progress = _updateBatchItem(
          progress: progress,
          index: index,
          status: ReceiptBatchItemStatus.failed,
          errorCode: analysis.errorCode,
          mappedItemCount: 0,
        );
        state = state.copyWith(progress: progress);
      }
    }

    final hasMappedItems = mappedItemsByIndex.values
        .expand((items) => items)
        .isNotEmpty;
    if (!hasMappedItems) {
      state = state.copyWith(status: ReceiptBatchFlowStatus.analysisFailed);
      return;
    }

    state = state.copyWith(status: ReceiptBatchFlowStatus.completed);
  }

  ReceiptBatchProgress _queuedBatchProgress(
    List<ReceiptInputSelection> selections,
  ) {
    return ReceiptBatchProgress(
      items: selections
          .map(
            (selection) => ReceiptBatchItemProgress(
              fileName: selection.name,
              status: ReceiptBatchItemStatus.queued,
            ),
          )
          .toList(growable: false),
    );
  }

  ReceiptBatchProgress _updateBatchItem({
    required ReceiptBatchProgress progress,
    required int index,
    required ReceiptBatchItemStatus status,
    String? errorCode,
    bool clearErrorCode = false,
    int? mappedItemCount,
  }) {
    final currentItem = progress.items[index];
    final updatedItem = currentItem.copyWith(
      status: status,
      errorCode: errorCode,
      clearErrorCode: clearErrorCode,
      mappedItemCount: mappedItemCount,
    );
    return progress.updateItem(index, updatedItem);
  }

  Future<({List<FridgeItem> mappedItems, String? errorCode})> _analyzeSelection(
    ReceiptInputSelection selection,
  ) async {
    try {
      final analysisRepository = ref.read(receiptAnalysisRepositoryProvider);
      final analysisResult = await analysisRepository.analyzeSelection(
        selection,
      );
      return switch (analysisResult) {
        ReceiptAnalysisSuccess(:final extraction) => (
          mappedItems: _mapExtraction(extraction),
          errorCode: null,
        ),
        ReceiptAnalysisFailure(:final errorCode) => (
          mappedItems: const <FridgeItem>[],
          errorCode: errorCode,
        ),
      };
    } catch (error, stackTrace) {
      log(
        'Receipt batch analysis failed for ${selection.name}',
        name: 'ReceiptBatchFlowController',
        error: error,
        stackTrace: stackTrace,
      );
      return (
        mappedItems: const <FridgeItem>[],
        errorCode: ReceiptAnalysisErrorCodes.unexpected,
      );
    }
  }

  List<FridgeItem> _mapExtraction(ReceiptAnalysisExtraction extraction) {
    final mapper = ref.read(receiptToFridgeItemMapperProvider);
    return mapper.map(extraction);
  }
}
