import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

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
    required List<FridgeItem> mappedItems,
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

  List<FridgeItem>? get mappedItems => switch (this) {
    ReceiptCaptureFlowCompleted(:final mappedItems) => mappedItems,
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
    this.mappedItemCount = 0,
  });

  final String fileName;
  final ReceiptBatchItemStatus status;
  final String? errorCode;
  final int mappedItemCount;

  ReceiptBatchItemProgress copyWith({
    ReceiptBatchItemStatus? status,
    String? errorCode,
    int? mappedItemCount,
    bool clearErrorCode = false,
  }) {
    return ReceiptBatchItemProgress(
      fileName: fileName,
      status: status ?? this.status,
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
      mappedItemCount: mappedItemCount ?? this.mappedItemCount,
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
    return items.where((item) => item.isFinished).length;
  }

  int get succeededCount {
    return items
        .where((item) => item.status == ReceiptBatchItemStatus.succeeded)
        .length;
  }

  int get failedCount {
    return items
        .where((item) => item.status == ReceiptBatchItemStatus.failed)
        .length;
  }

  bool get hasFailures => failedCount > 0;

  bool get hasSuccesses => succeededCount > 0;

  ReceiptBatchProgress updateItem(int index, ReceiptBatchItemProgress item) {
    final nextItems = List<ReceiptBatchItemProgress>.of(items);
    nextItems[index] = item;
    return ReceiptBatchProgress(items: nextItems);
  }
}

enum ReceiptBatchRunStatus { completed, inputCanceled, inputFailed }

class ReceiptBatchRunResult {
  const ReceiptBatchRunResult({
    required this.status,
    required this.progress,
    required this.mappedItems,
    this.errorCode,
  });

  const ReceiptBatchRunResult.completed({
    required ReceiptBatchProgress progress,
    required List<FridgeItem> mappedItems,
  }) : this(
         status: ReceiptBatchRunStatus.completed,
         progress: progress,
         mappedItems: mappedItems,
       );

  const ReceiptBatchRunResult.inputCanceled()
    : this(
        status: ReceiptBatchRunStatus.inputCanceled,
        progress: const ReceiptBatchProgress(items: []),
        mappedItems: const <FridgeItem>[],
      );

  const ReceiptBatchRunResult.inputFailed({required String errorCode})
    : this(
        status: ReceiptBatchRunStatus.inputFailed,
        progress: const ReceiptBatchProgress(items: []),
        mappedItems: const <FridgeItem>[],
        errorCode: errorCode,
      );

  final ReceiptBatchRunStatus status;
  final ReceiptBatchProgress progress;
  final List<FridgeItem> mappedItems;
  final String? errorCode;
}
