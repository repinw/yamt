import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

part 'receipt_capture_flow_models.freezed.dart';

/// Defines receipt capture flow status.
enum ReceiptCaptureFlowStatus {
  /// Documented member.
  completed,

  /// Documented member.
  inputCanceled,

  /// Documented member.
  inputUnsupported,

  /// Documented member.
  inputFailed,

  /// Documented member.
  analysisFailed,
}

/// Defines receipt capture flow result.
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

  /// The status.
  ReceiptCaptureFlowStatus get status => switch (this) {
    ReceiptCaptureFlowCompleted() => ReceiptCaptureFlowStatus.completed,
    ReceiptCaptureFlowInputCanceled() => ReceiptCaptureFlowStatus.inputCanceled,
    ReceiptCaptureFlowInputUnsupported() =>
      ReceiptCaptureFlowStatus.inputUnsupported,
    ReceiptCaptureFlowInputFailed() => ReceiptCaptureFlowStatus.inputFailed,
    ReceiptCaptureFlowAnalysisFailed() =>
      ReceiptCaptureFlowStatus.analysisFailed,
  };

  /// The error code.
  String? get errorCode => switch (this) {
    ReceiptCaptureFlowInputUnsupported(:final errorCode) => errorCode,
    ReceiptCaptureFlowInputFailed(:final errorCode) => errorCode,
    ReceiptCaptureFlowAnalysisFailed(:final errorCode) => errorCode,
    ReceiptCaptureFlowCompleted() || ReceiptCaptureFlowInputCanceled() => null,
  };

  /// The extraction.
  ReceiptAnalysisExtraction? get extraction => switch (this) {
    ReceiptCaptureFlowCompleted(:final extraction) => extraction,
    ReceiptCaptureFlowInputCanceled() ||
    ReceiptCaptureFlowInputUnsupported() ||
    ReceiptCaptureFlowInputFailed() ||
    ReceiptCaptureFlowAnalysisFailed() => null,
  };

  /// The review drafts.
  List<ReceiptReviewItemDraft>? get reviewDrafts => switch (this) {
    ReceiptCaptureFlowCompleted(:final reviewDrafts) => reviewDrafts,
    ReceiptCaptureFlowInputCanceled() ||
    ReceiptCaptureFlowInputUnsupported() ||
    ReceiptCaptureFlowInputFailed() ||
    ReceiptCaptureFlowAnalysisFailed() => null,
  };

  /// The receipt preview bytes.
  Uint8List? get receiptPreviewBytes => switch (this) {
    ReceiptCaptureFlowCompleted(:final receiptPreviewBytes) =>
      receiptPreviewBytes,
    ReceiptCaptureFlowInputCanceled() ||
    ReceiptCaptureFlowInputUnsupported() ||
    ReceiptCaptureFlowInputFailed() ||
    ReceiptCaptureFlowAnalysisFailed() => null,
  };

  /// Whether completed.
  bool get isCompleted => status == ReceiptCaptureFlowStatus.completed;
}

/// Defines receipt batch item status.
enum ReceiptBatchItemStatus {
  /// Queued.
  queued,

  /// Processing.
  processing,

  /// Succeeded.
  succeeded,

  /// Failed.
  failed,
}

/// Defines receipt batch item progress.
class ReceiptBatchItemProgress {
  /// The receipt batch item progress.
  const ReceiptBatchItemProgress({
    required this.fileName,
    required this.status,
    this.errorCode,
    this.reviewDraftCount = 0,
  });

  /// The file name.
  final String fileName;

  /// The status.
  final ReceiptBatchItemStatus status;

  /// The error code.
  final String? errorCode;

  /// The review draft count.
  final int reviewDraftCount;

  /// Copy with.
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

  /// Whether finished.
  bool get isFinished =>
      status == ReceiptBatchItemStatus.succeeded ||
      status == ReceiptBatchItemStatus.failed;
}

/// Defines receipt batch progress.
class ReceiptBatchProgress {
  /// The receipt batch progress.
  const ReceiptBatchProgress({required this.items});

  /// The items.
  final List<ReceiptBatchItemProgress> items;

  /// The total count.
  int get totalCount => items.length;

  /// The processed count.
  int get processedCount {
    return _countWhere((item) => item.isFinished);
  }

  /// The succeeded count.
  int get succeededCount {
    return _countWhere(
      (item) => item.status == ReceiptBatchItemStatus.succeeded,
    );
  }

  /// The failed count.
  int get failedCount {
    return _countWhere((item) => item.status == ReceiptBatchItemStatus.failed);
  }

  /// Whether failures.
  bool get hasFailures => failedCount > 0;

  /// Whether successes.
  bool get hasSuccesses => succeededCount > 0;

  /// Update item.
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

/// Defines receipt batch run status.
enum ReceiptBatchRunStatus {
  /// Completed.
  completed,

  /// Input canceled.
  inputCanceled,

  /// Input failed.
  inputFailed,
}

/// Defines receipt batch run result.
class ReceiptBatchRunResult {
  /// The receipt batch run result.
  const ReceiptBatchRunResult({
    required this.status,
    required this.progress,
    required this.reviewDrafts,
    this.errorCode,
  });

  /// Creates a [ReceiptBatchRunResult] for completed.
  const ReceiptBatchRunResult.completed({
    required ReceiptBatchProgress progress,
    required List<ReceiptReviewItemDraft> reviewDrafts,
  }) : this(
         status: ReceiptBatchRunStatus.completed,
         progress: progress,
         reviewDrafts: reviewDrafts,
       );

  /// The receipt batch progress.
  const ReceiptBatchRunResult.inputCanceled()
    : this(
        status: ReceiptBatchRunStatus.inputCanceled,
        progress: const ReceiptBatchProgress(items: []),
        reviewDrafts: const <ReceiptReviewItemDraft>[],
      );

  /// Creates a [ReceiptBatchRunResult] for input failed.
  const ReceiptBatchRunResult.inputFailed({required String errorCode})
    : this(
        status: ReceiptBatchRunStatus.inputFailed,
        progress: const ReceiptBatchProgress(items: []),
        reviewDrafts: const <ReceiptReviewItemDraft>[],
        errorCode: errorCode,
      );

  /// The status.
  final ReceiptBatchRunStatus status;

  /// The progress.
  final ReceiptBatchProgress progress;

  /// The review drafts.
  final List<ReceiptReviewItemDraft> reviewDrafts;

  /// The error code.
  final String? errorCode;
}
