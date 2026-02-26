import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';

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
    this.mappedItemsByIndex = const <int, List<FridgeItem>>{},
    this.pendingAutoReviewIndex,
    this.autoReviewDispatched = false,
    this.errorCode,
  });

  final ReceiptBatchFlowStatus status;
  final ReceiptBatchProgress progress;
  final Set<int> reviewableIndices;
  final Set<int> reviewedIndices;
  final Map<int, List<FridgeItem>> mappedItemsByIndex;
  final int? pendingAutoReviewIndex;
  final bool autoReviewDispatched;
  final String? errorCode;

  bool get canClose => status == ReceiptBatchFlowStatus.completed;

  List<FridgeItem> mappedItemsForIndex(int index) {
    return mappedItemsByIndex[index] ?? const <FridgeItem>[];
  }

  ReceiptBatchFlowState copyWith({
    ReceiptBatchFlowStatus? status,
    ReceiptBatchProgress? progress,
    Set<int>? reviewableIndices,
    Set<int>? reviewedIndices,
    Map<int, List<FridgeItem>>? mappedItemsByIndex,
    int? pendingAutoReviewIndex,
    bool clearPendingAutoReview = false,
    bool? autoReviewDispatched,
    String? errorCode,
    bool clearErrorCode = false,
  }) {
    return ReceiptBatchFlowState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      reviewableIndices: reviewableIndices ?? this.reviewableIndices,
      reviewedIndices: reviewedIndices ?? this.reviewedIndices,
      mappedItemsByIndex: mappedItemsByIndex ?? this.mappedItemsByIndex,
      pendingAutoReviewIndex: clearPendingAutoReview
          ? null
          : (pendingAutoReviewIndex ?? this.pendingAutoReviewIndex),
      autoReviewDispatched: autoReviewDispatched ?? this.autoReviewDispatched,
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
    );
  }
}
