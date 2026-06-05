import 'dart:developer' show log;

import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

/// Defines receipt batch process result.
class ReceiptBatchProcessResult {
  /// The receipt batch process result.
  const ReceiptBatchProcessResult({
    required this.progress,
    required this.reviewDraftsByIndex,
    required this.wasCanceled,
  });

  /// The progress.
  final ReceiptBatchProgress progress;

  /// The review drafts by index.
  final Map<int, List<ReceiptReviewItemDraft>> reviewDraftsByIndex;

  /// Whether canceled.
  final bool wasCanceled;

  /// Whether review drafts.
  bool get hasReviewDrafts =>
      reviewDraftsByIndex.values.any((items) => items.isNotEmpty);

  /// The review drafts.
  List<ReceiptReviewItemDraft> get reviewDrafts => reviewDraftsByIndex.values
      .expand((items) => items)
      .toList(growable: false);
}

/// Defines receipt batch processor.
class ReceiptBatchProcessor {
  /// The receipt batch processor.
  const ReceiptBatchProcessor({
    required ReceiptAnalysisRepository analysisRepository,
    required Future<List<ReceiptReviewItemDraft>> Function(
      ReceiptAnalysisExtraction extraction,
    )
    mapExtraction,
    required this.loggerName,
  }) : _analysisRepository = analysisRepository,
       _mapExtraction = mapExtraction;

  final ReceiptAnalysisRepository _analysisRepository;
  final Future<List<ReceiptReviewItemDraft>> Function(
    ReceiptAnalysisExtraction extraction,
  )
  _mapExtraction;

  /// The logger name.
  final String loggerName;

  /// Process selections.
  Future<ReceiptBatchProcessResult> processSelections(
    List<ReceiptInputSelection> selections, {
    required bool Function() shouldContinue,
    void Function(ReceiptBatchProgress progress)? onProgressChanged,
    void Function(
      int index,
      List<ReceiptReviewItemDraft> reviewDrafts,
      ReceiptBatchProgress progress,
    )?
    onItemSucceeded,
    void Function(int index, ReceiptBatchProgress progress)? onItemFailed,
  }) async {
    var progress = _queuedBatchProgress(selections);
    var reviewDraftsByIndex = <int, List<ReceiptReviewItemDraft>>{};
    onProgressChanged?.call(progress);

    for (var index = 0; index < selections.length; index++) {
      if (!shouldContinue()) {
        return ReceiptBatchProcessResult(
          progress: progress,
          reviewDraftsByIndex: reviewDraftsByIndex,
          wasCanceled: true,
        );
      }

      progress = _updateBatchItem(
        progress: progress,
        index: index,
        status: ReceiptBatchItemStatus.processing,
        clearErrorCode: true,
      );
      onProgressChanged?.call(progress);

      // Keep processing sequential to avoid API bursts and memory spikes.
      final analysis = await _analyzeSelection(selections[index]);
      if (!shouldContinue()) {
        return ReceiptBatchProcessResult(
          progress: progress,
          reviewDraftsByIndex: reviewDraftsByIndex,
          wasCanceled: true,
        );
      }

      if (analysis.errorCode == null) {
        reviewDraftsByIndex = <int, List<ReceiptReviewItemDraft>>{
          ...reviewDraftsByIndex,
          index: analysis.reviewDrafts,
        };
        progress = _updateBatchItem(
          progress: progress,
          index: index,
          status: ReceiptBatchItemStatus.succeeded,
          reviewDraftCount: analysis.reviewDrafts.length,
          clearErrorCode: true,
        );
        onItemSucceeded?.call(index, analysis.reviewDrafts, progress);
      } else {
        progress = _updateBatchItem(
          progress: progress,
          index: index,
          status: ReceiptBatchItemStatus.failed,
          errorCode: analysis.errorCode,
          reviewDraftCount: 0,
        );
        onItemFailed?.call(index, progress);
      }
    }

    return ReceiptBatchProcessResult(
      progress: progress,
      reviewDraftsByIndex: reviewDraftsByIndex,
      wasCanceled: false,
    );
  }

  Future<({List<ReceiptReviewItemDraft> reviewDrafts, String? errorCode})>
  _analyzeSelection(ReceiptInputSelection selection) async {
    try {
      final analysisResult = await _analysisRepository.analyzeSelection(
        selection,
      );
      return switch (analysisResult) {
        ReceiptAnalysisSuccess(:final extraction) => (
          reviewDrafts: await _mapExtraction(extraction),
          errorCode: null,
        ),
        ReceiptAnalysisFailure(:final errorCode) => (
          reviewDrafts: const <ReceiptReviewItemDraft>[],
          errorCode: errorCode,
        ),
      };
    } on Object catch (error, stackTrace) {
      log(
        'Receipt batch analysis failed for ${selection.name}',
        name: loggerName,
        error: error,
        stackTrace: stackTrace,
      );
      return (
        reviewDrafts: const <ReceiptReviewItemDraft>[],
        errorCode: ReceiptAnalysisErrorCodes.unexpected,
      );
    }
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
    int? reviewDraftCount,
  }) {
    final currentItem = progress.items[index];
    final updatedItem = currentItem.copyWith(
      status: status,
      errorCode: errorCode,
      clearErrorCode: clearErrorCode,
      reviewDraftCount: reviewDraftCount,
    );
    return progress.updateItem(index, updatedItem);
  }
}
