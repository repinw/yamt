import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_analysis_models.freezed.dart';

enum ReceiptAnalysisStatus { succeeded, failed }

abstract final class ReceiptAnalysisErrorCodes {
  static const notImplemented = 'analysis_not_implemented';
  static const emptyResponse = 'analysis_empty_response';
  static const aiRequestFailed = 'analysis_ai_request_failed';
  static const parseFailed = 'analysis_parse_failed';
  static const storageFailed = 'analysis_storage_failed';
  static const unexpected = 'analysis_unexpected';
}

@freezed
abstract class ReceiptAnalysisExtraction with _$ReceiptAnalysisExtraction {
  const factory ReceiptAnalysisExtraction({
    required Map<String, dynamic> root,
    required List<ReceiptAnalysisItem> items,
  }) = _ReceiptAnalysisExtraction;
}

@freezed
abstract class ReceiptAnalysisItem with _$ReceiptAnalysisItem {
  const factory ReceiptAnalysisItem({
    required String name,
    required Map<String, dynamic> rawPayload,
  }) = _ReceiptAnalysisItem;
}

@freezed
sealed class ReceiptAnalysisResult with _$ReceiptAnalysisResult {
  const ReceiptAnalysisResult._();

  const factory ReceiptAnalysisResult.succeeded({
    required String rawResponse,
    required ReceiptAnalysisExtraction extraction,
  }) = ReceiptAnalysisSuccess;

  const factory ReceiptAnalysisResult.failed({required String errorCode}) =
      ReceiptAnalysisFailure;

  ReceiptAnalysisStatus get status => switch (this) {
    ReceiptAnalysisSuccess() => ReceiptAnalysisStatus.succeeded,
    ReceiptAnalysisFailure() => ReceiptAnalysisStatus.failed,
  };

  bool get isSuccess => status == ReceiptAnalysisStatus.succeeded;

  String? get errorCode => switch (this) {
    ReceiptAnalysisFailure(:final errorCode) => errorCode,
    ReceiptAnalysisSuccess() => null,
  };
}
