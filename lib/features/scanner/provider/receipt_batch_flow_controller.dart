import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/data/receipt_to_fridge_item_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_processor.dart';
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

  bool startReview(int index) {
    if (!state.reviewableIndices.contains(index)) {
      return false;
    }
    if (state.isReviewOpen) {
      return false;
    }
    state = state.copyWith(
      activeReviewIndex: index,
      clearPendingAutoReview: state.pendingAutoReviewIndex == index,
    );
    return true;
  }

  void finishReview({required int index, required bool saved}) {
    if (state.activeReviewIndex != index) {
      return;
    }
    final reviewedIndices = saved
        ? <int>{...state.reviewedIndices, index}
        : state.reviewedIndices;
    state = state.copyWith(
      reviewedIndices: reviewedIndices,
      clearActiveReviewIndex: true,
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
    var mappedItemsByIndex = const <int, List<FridgeItem>>{};
    var reviewableIndices = const <int>{};
    state = state.copyWith(
      status: ReceiptBatchFlowStatus.running,
      progress: const ReceiptBatchProgress(items: <ReceiptBatchItemProgress>[]),
      reviewableIndices: reviewableIndices,
      reviewedIndices: <int>{},
      mappedItemsByIndex: mappedItemsByIndex,
      clearPendingAutoReview: true,
      clearActiveReviewIndex: true,
      autoReviewDispatched: false,
      clearErrorCode: true,
    );

    final batchProcessor = _batchProcessor();
    final result = await batchProcessor.processSelections(
      selections,
      shouldContinue: () => ref.mounted,
      onProgressChanged: (progress) {
        if (!ref.mounted) {
          return;
        }
        state = state.copyWith(progress: progress);
      },
      onItemSucceeded: (index, mappedItems, progress) {
        if (!ref.mounted) {
          return;
        }

        mappedItemsByIndex = <int, List<FridgeItem>>{
          ...mappedItemsByIndex,
          index: mappedItems,
        };
        reviewableIndices = <int>{...reviewableIndices, index};
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
      },
      onItemFailed: (_, progress) {
        if (!ref.mounted) {
          return;
        }
        state = state.copyWith(progress: progress);
      },
    );
    if (!ref.mounted || result.wasCanceled) {
      return;
    }

    if (!result.hasMappedItems) {
      state = state.copyWith(
        status: ReceiptBatchFlowStatus.analysisFailed,
        progress: result.progress,
      );
      return;
    }

    state = state.copyWith(
      status: ReceiptBatchFlowStatus.completed,
      progress: result.progress,
      mappedItemsByIndex: result.mappedItemsByIndex,
      reviewableIndices: result.mappedItemsByIndex.keys.toSet(),
    );
  }

  ReceiptBatchProcessor _batchProcessor() {
    final analysisRepository = ref.read(receiptAnalysisRepositoryProvider);
    final mapper = ref.read(receiptToFridgeItemMapperProvider);
    return ReceiptBatchProcessor(
      analysisRepository: analysisRepository,
      mapExtraction: mapper.map,
      loggerName: 'ReceiptBatchFlowController',
    );
  }
}
