import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/application/'
    'receipt_review_resolution_service.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_processor.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

part 'receipt_batch_flow_controller.g.dart';

/// Defines receipt batch flow controller.
@riverpod
class ReceiptBatchFlowController extends _$ReceiptBatchFlowController {
  Future<void>? _activeBatchRun;

  @override
  ReceiptBatchFlowState build() {
    return const ReceiptBatchFlowState();
  }

  /// Reset.
  void reset() {
    state = const ReceiptBatchFlowState();
  }

  /// Start review.
  bool startReview(int index) {
    if (!state.reviewableIndices.contains(index)) {
      return false;
    }
    if (state.isReviewOpen) {
      return false;
    }
    final pendingAutoReviewIndex = state.pendingAutoReviewIndex == index
        ? null
        : state.pendingAutoReviewIndex;
    state = state.copyWith(
      activeReviewIndex: index,
      pendingAutoReviewIndex: pendingAutoReviewIndex,
    );
    return true;
  }

  /// Finish review.
  void finishReview({required int index, required bool saved}) {
    if (state.activeReviewIndex != index) {
      return;
    }
    final reviewedIndices = saved
        ? <int>{...state.reviewedIndices, index}
        : state.reviewedIndices;
    state = state.copyWith(
      reviewedIndices: reviewedIndices,
      activeReviewIndex: null,
    );
  }

  /// Consume pending auto review.
  void consumePendingAutoReview() {
    state = state.copyWith(pendingAutoReviewIndex: null);
  }

  /// Run file batch.
  Future<void> runFileBatch() async {
    final inFlight = _activeBatchRun;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final operation = _runFileBatchInternal();
    _activeBatchRun = operation;
    try {
      await operation;
    } finally {
      if (identical(_activeBatchRun, operation)) {
        _activeBatchRun = null;
      }
    }
  }

  /// Run selections.
  Future<void> runSelections(List<ReceiptInputSelection> selections) async {
    final inFlight = _activeBatchRun;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final operation = _runSelectionsInternal(selections);
    _activeBatchRun = operation;
    try {
      await operation;
    } finally {
      if (identical(_activeBatchRun, operation)) {
        _activeBatchRun = null;
      }
    }
  }

  Future<void> _runFileBatchInternal() async {
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
        );
    }
  }

  Future<void> _runSelectionsInternal(
    List<ReceiptInputSelection> selections,
  ) async {
    state = const ReceiptBatchFlowState(status: ReceiptBatchFlowStatus.running);
    await _runSelectedBatch(selections);
  }

  Future<void> _runSelectedBatch(List<ReceiptInputSelection> selections) async {
    var reviewDraftsByIndex = const <int, List<ReceiptReviewItemDraft>>{};
    var reviewableIndices = const <int>{};
    state = state.copyWith(
      status: ReceiptBatchFlowStatus.running,
      progress: const ReceiptBatchProgress(items: <ReceiptBatchItemProgress>[]),
      reviewableIndices: reviewableIndices,
      reviewedIndices: <int>{},
      reviewDraftsByIndex: reviewDraftsByIndex,
      pendingAutoReviewIndex: null,
      activeReviewIndex: null,
      autoReviewDispatched: false,
      errorCode: null,
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
      onItemSucceeded: (index, reviewDrafts, progress) {
        if (!ref.mounted) {
          return;
        }

        reviewDraftsByIndex = <int, List<ReceiptReviewItemDraft>>{
          ...reviewDraftsByIndex,
          index: reviewDrafts,
        };
        reviewableIndices = <int>{...reviewableIndices, index};
        final shouldDispatchAutoReview = !state.autoReviewDispatched;
        state = state.copyWith(
          progress: progress,
          reviewDraftsByIndex: reviewDraftsByIndex,
          reviewableIndices: reviewableIndices,
          pendingAutoReviewIndex: shouldDispatchAutoReview ? index : null,
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

    if (!result.hasReviewDrafts) {
      state = state.copyWith(
        status: ReceiptBatchFlowStatus.analysisFailed,
        progress: result.progress,
      );
      return;
    }

    state = state.copyWith(
      status: ReceiptBatchFlowStatus.completed,
      progress: result.progress,
      reviewDraftsByIndex: result.reviewDraftsByIndex,
      reviewableIndices: result.reviewDraftsByIndex.keys.toSet(),
    );
  }

  ReceiptBatchProcessor _batchProcessor() {
    final analysisRepository = ref.read(receiptAnalysisRepositoryProvider);
    final resolutionService = ref.read(receiptReviewResolutionServiceProvider);
    return ReceiptBatchProcessor(
      analysisRepository: analysisRepository,
      mapExtraction: resolutionService.prepareDrafts,
      loggerName: 'ReceiptBatchFlowController',
    );
  }
}
