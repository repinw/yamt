import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

enum ReceiptBatchFlowStatus {
  idle,
  running,
  inputCanceled,
  inputFailed,
  analysisFailed,
  completed,
}

class ReceiptBatchFlowState {
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

  final ReceiptBatchFlowStatus status;
  final ReceiptBatchProgress progress;
  final Set<int> reviewableIndices;
  final Set<int> reviewedIndices;
  final Map<int, List<ReceiptReviewItemDraft>> reviewDraftsByIndex;
  final int? pendingAutoReviewIndex;
  final bool autoReviewDispatched;
  final int? activeReviewIndex;
  final String? errorCode;

  bool get canClose => status == ReceiptBatchFlowStatus.completed;
  bool get isReviewOpen => activeReviewIndex != null;

  List<ReceiptReviewItemDraft> reviewDraftsForIndex(int index) {
    return reviewDraftsByIndex[index] ?? const <ReceiptReviewItemDraft>[];
  }

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
