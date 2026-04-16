import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

/// Defines receipt batch flow status.
enum ReceiptBatchFlowStatus {
  /// Documented member.
  idle,

  /// Documented member.
  running,

  /// Documented member.
  inputCanceled,

  /// Documented member.
  inputFailed,

  /// Documented member.
  analysisFailed,

  /// Documented member.
  completed,
}

/// Defines receipt batch flow state.
class ReceiptBatchFlowState {
  /// The receipt batch flow state.
  const ReceiptBatchFlowState({
    this.status = ReceiptBatchFlowStatus.idle,
    this.progress = const ReceiptBatchProgress(
      items: <ReceiptBatchItemProgress>[],
    ),
    this.reviewableIndices = const <int>{},
    this.reviewedIndices = const <int>{},
    this.reviewDraftsByIndex = const <int, List<ReceiptReviewItemDraft>>{},
    this.pendingAutoReviewIndex,
    this.autoReviewDispatched = false,
    this.activeReviewIndex,
    this.errorCode,
  });

  /// The status.
  final ReceiptBatchFlowStatus status;

  /// The progress.
  final ReceiptBatchProgress progress;

  /// The reviewable indices.
  final Set<int> reviewableIndices;

  /// The reviewed indices.
  final Set<int> reviewedIndices;

  /// The review drafts by index.
  final Map<int, List<ReceiptReviewItemDraft>> reviewDraftsByIndex;

  /// The pending auto review index.
  final int? pendingAutoReviewIndex;

  /// The auto review dispatched.
  final bool autoReviewDispatched;

  /// The active review index.
  final int? activeReviewIndex;

  /// The error code.
  final String? errorCode;

  /// Whether close.
  bool get canClose => status == ReceiptBatchFlowStatus.completed;

  /// Whether review open.
  bool get isReviewOpen => activeReviewIndex != null;

  /// Review drafts for index.
  List<ReceiptReviewItemDraft> reviewDraftsForIndex(int index) {
    return reviewDraftsByIndex[index] ?? const <ReceiptReviewItemDraft>[];
  }

  /// Copy with.
  ReceiptBatchFlowState copyWith({
    ReceiptBatchFlowStatus? status,
    ReceiptBatchProgress? progress,
    Set<int>? reviewableIndices,
    Set<int>? reviewedIndices,
    Map<int, List<ReceiptReviewItemDraft>>? reviewDraftsByIndex,
    Object? pendingAutoReviewIndex = _keepFieldValue,
    bool? autoReviewDispatched,
    Object? activeReviewIndex = _keepFieldValue,
    Object? errorCode = _keepFieldValue,
  }) {
    return ReceiptBatchFlowState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      reviewableIndices: reviewableIndices ?? this.reviewableIndices,
      reviewedIndices: reviewedIndices ?? this.reviewedIndices,
      reviewDraftsByIndex: reviewDraftsByIndex ?? this.reviewDraftsByIndex,
      pendingAutoReviewIndex: pendingAutoReviewIndex == _keepFieldValue
          ? this.pendingAutoReviewIndex
          : pendingAutoReviewIndex as int?,
      autoReviewDispatched: autoReviewDispatched ?? this.autoReviewDispatched,
      activeReviewIndex: activeReviewIndex == _keepFieldValue
          ? this.activeReviewIndex
          : activeReviewIndex as int?,
      errorCode: errorCode == _keepFieldValue
          ? this.errorCode
          : errorCode as String?,
    );
  }
}

const Object _keepFieldValue = Object();
