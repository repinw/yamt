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
