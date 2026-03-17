import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

part 'receipt_capture_flow_models.freezed.dart';

enum ReceiptCaptureFlowStatus {
  completed,
  inputCanceled,
  inputUnsupported,
  inputFailed,
  analysisFailed,
}

@freezed
sealed class ReceiptCaptureFlowResult with _$ReceiptCaptureFlowResult {
  const ReceiptCaptureFlowResult._();

  const factory ReceiptCaptureFlowResult.completed({
    required ReceiptInputSource source,
    required ReceiptAnalysisExtraction extraction,
    required List<ReceiptReviewItemDraft> reviewDrafts,
    Uint8List? receiptPreviewBytes,
  }) = ReceiptCaptureFlowCompleted;

  const factory ReceiptCaptureFlowResult.inputCanceled({
    required ReceiptInputSource source,
  }) = ReceiptCaptureFlowInputCanceled;

  const factory ReceiptCaptureFlowResult.inputUnsupported({
    required ReceiptInputSource source,
    required String errorCode,
  }) = ReceiptCaptureFlowInputUnsupported;

  const factory ReceiptCaptureFlowResult.inputFailed({
    required ReceiptInputSource source,
    required String errorCode,
  }) = ReceiptCaptureFlowInputFailed;

  const factory ReceiptCaptureFlowResult.analysisFailed({
    required ReceiptInputSource source,
    required String errorCode,
  }) = ReceiptCaptureFlowAnalysisFailed;

  ReceiptCaptureFlowStatus get status => switch (this) {
    ReceiptCaptureFlowCompleted() => ReceiptCaptureFlowStatus.completed,
    ReceiptCaptureFlowInputCanceled() => ReceiptCaptureFlowStatus.inputCanceled,
    ReceiptCaptureFlowInputUnsupported() =>
      ReceiptCaptureFlowStatus.inputUnsupported,
    ReceiptCaptureFlowInputFailed() => ReceiptCaptureFlowStatus.inputFailed,
    ReceiptCaptureFlowAnalysisFailed() =>
      ReceiptCaptureFlowStatus.analysisFailed,
  };

  String? get errorCode => switch (this) {
    ReceiptCaptureFlowInputUnsupported(:final errorCode) => errorCode,
    ReceiptCaptureFlowInputFailed(:final errorCode) => errorCode,
    ReceiptCaptureFlowAnalysisFailed(:final errorCode) => errorCode,
    ReceiptCaptureFlowCompleted() || ReceiptCaptureFlowInputCanceled() => null,
  };

  ReceiptAnalysisExtraction? get extraction => switch (this) {
    ReceiptCaptureFlowCompleted(:final extraction) => extraction,
    ReceiptCaptureFlowInputCanceled() ||
    ReceiptCaptureFlowInputUnsupported() ||
    ReceiptCaptureFlowInputFailed() ||
    ReceiptCaptureFlowAnalysisFailed() => null,
  };

  List<ReceiptReviewItemDraft>? get reviewDrafts => switch (this) {
    ReceiptCaptureFlowCompleted(:final reviewDrafts) => reviewDrafts,
    ReceiptCaptureFlowInputCanceled() ||
    ReceiptCaptureFlowInputUnsupported() ||
    ReceiptCaptureFlowInputFailed() ||
    ReceiptCaptureFlowAnalysisFailed() => null,
  };

  Uint8List? get receiptPreviewBytes => switch (this) {
    ReceiptCaptureFlowCompleted(:final receiptPreviewBytes) =>
      receiptPreviewBytes,
    ReceiptCaptureFlowInputCanceled() ||
    ReceiptCaptureFlowInputUnsupported() ||
    ReceiptCaptureFlowInputFailed() ||
    ReceiptCaptureFlowAnalysisFailed() => null,
  };

  bool get isCompleted => status == ReceiptCaptureFlowStatus.completed;
}

enum ReceiptBatchItemStatus { queued, processing, succeeded, failed }

class ReceiptBatchItemProgress {
  const ReceiptBatchItemProgress({
    required this.fileName,
    required this.status,
    this.errorCode,
    this.reviewDraftCount = 0,
  });

  final String fileName;
  final ReceiptBatchItemStatus status;
  final String? errorCode;
  final int reviewDraftCount;

  ReceiptBatchItemProgress copyWith({
    ReceiptBatchItemStatus? status,
    String? errorCode,
    int? reviewDraftCount,
    bool clearErrorCode = false,
  }) {
    return ReceiptBatchItemProgress(
      fileName: fileName,
      status: status ?? this.status,
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
      reviewDraftCount: reviewDraftCount ?? this.reviewDraftCount,
    );
  }

  bool get isFinished =>
      status == ReceiptBatchItemStatus.succeeded ||
      status == ReceiptBatchItemStatus.failed;
}

class ReceiptBatchProgress {
  const ReceiptBatchProgress({required this.items});

  final List<ReceiptBatchItemProgress> items;

  int get totalCount => items.length;

  int get processedCount {
    return _countWhere((item) => item.isFinished);
  }

  int get succeededCount {
    return _countWhere(
      (item) => item.status == ReceiptBatchItemStatus.succeeded,
    );
  }

  int get failedCount {
    return _countWhere((item) => item.status == ReceiptBatchItemStatus.failed);
  }

  bool get hasFailures => failedCount > 0;

  bool get hasSuccesses => succeededCount > 0;

  ReceiptBatchProgress updateItem(int index, ReceiptBatchItemProgress item) {
    final nextItems = List<ReceiptBatchItemProgress>.of(items);
    nextItems[index] = item;
    return ReceiptBatchProgress(items: nextItems);
  }

  int _countWhere(bool Function(ReceiptBatchItemProgress item) predicate) {
    var count = 0;
    for (final item in items) {
      if (predicate(item)) {
        count += 1;
      }
    }
    return count;
  }
}

enum ReceiptBatchRunStatus { completed, inputCanceled, inputFailed }

class ReceiptBatchRunResult {
  const ReceiptBatchRunResult({
    required this.status,
    required this.progress,
    required this.reviewDrafts,
    this.errorCode,
  });

  const ReceiptBatchRunResult.completed({
    required ReceiptBatchProgress progress,
    required List<ReceiptReviewItemDraft> reviewDrafts,
  }) : this(
         status: ReceiptBatchRunStatus.completed,
         progress: progress,
         reviewDrafts: reviewDrafts,
       );

  const ReceiptBatchRunResult.inputCanceled()
    : this(
        status: ReceiptBatchRunStatus.inputCanceled,
        progress: const ReceiptBatchProgress(items: []),
        reviewDrafts: const <ReceiptReviewItemDraft>[],
      );

  const ReceiptBatchRunResult.inputFailed({required String errorCode})
    : this(
        status: ReceiptBatchRunStatus.inputFailed,
        progress: const ReceiptBatchProgress(items: []),
        reviewDrafts: const <ReceiptReviewItemDraft>[],
        errorCode: errorCode,
      );

  final ReceiptBatchRunStatus status;
  final ReceiptBatchProgress progress;
  final List<ReceiptReviewItemDraft> reviewDrafts;
  final String? errorCode;
}
