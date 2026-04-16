import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_analysis_models.freezed.dart';

/// Defines receipt analysis status.
enum ReceiptAnalysisStatus {
  /// Succeeded.
  succeeded,

  /// Failed.
  failed,
}

/// Defines receipt analysis error codes.
abstract final class ReceiptAnalysisErrorCodes {
  /// The not implemented.
  static const notImplemented = 'analysis_not_implemented';

  /// The empty response.
  static const emptyResponse = 'analysis_empty_response';

  /// The ai request failed.
  static const aiRequestFailed = 'analysis_ai_request_failed';

  /// The parse failed.
  static const parseFailed = 'analysis_parse_failed';

  /// The storage failed.
  static const storageFailed = 'analysis_storage_failed';

  /// The unexpected.
  static const unexpected = 'analysis_unexpected';
}

/// Defines receipt analysis extraction.
@freezed
abstract class ReceiptAnalysisExtraction with _$ReceiptAnalysisExtraction {
  /// The receipt analysis extraction.
  const factory ReceiptAnalysisExtraction({
    required Map<String, dynamic> root,
    required List<ReceiptAnalysisItem> items,
  }) = _ReceiptAnalysisExtraction;
}

/// Defines receipt analysis item.
@freezed
abstract class ReceiptAnalysisItem with _$ReceiptAnalysisItem {
  /// The receipt analysis item.
  const factory ReceiptAnalysisItem({
    required String name,
    required Map<String, dynamic> rawPayload,
  }) = _ReceiptAnalysisItem;
}

/// Defines receipt analysis result.
@freezed
sealed class ReceiptAnalysisResult with _$ReceiptAnalysisResult {
  const ReceiptAnalysisResult._();

  const factory ReceiptAnalysisResult.succeeded({
    required String rawResponse,
    required ReceiptAnalysisExtraction extraction,
  }) = ReceiptAnalysisSuccess;

  const factory ReceiptAnalysisResult.failed({required String errorCode}) =
      ReceiptAnalysisFailure;

  /// The status.
  ReceiptAnalysisStatus get status => switch (this) {
    ReceiptAnalysisSuccess() => ReceiptAnalysisStatus.succeeded,
    ReceiptAnalysisFailure() => ReceiptAnalysisStatus.failed,
  };

  /// Whether success.
  bool get isSuccess => status == ReceiptAnalysisStatus.succeeded;

  /// The error code.
  String? get errorCode => switch (this) {
    ReceiptAnalysisFailure(:final errorCode) => errorCode,
    ReceiptAnalysisSuccess() => null,
  };
}
