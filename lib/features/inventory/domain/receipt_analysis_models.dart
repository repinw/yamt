enum ReceiptAnalysisStatus { succeeded, failed }

abstract final class ReceiptAnalysisErrorCodes {
  static const notImplemented = 'analysis_not_implemented';
  static const templateConfigFailed = 'analysis_template_config_failed';
  static const emptyResponse = 'analysis_empty_response';
  static const aiRequestFailed = 'analysis_ai_request_failed';
  static const unexpected = 'analysis_unexpected';
}

class ReceiptAnalysisResult {
  const ReceiptAnalysisResult({
    required this.status,
    this.rawResponse,
    this.errorCode,
  });

  const ReceiptAnalysisResult.succeeded({required String rawResponse})
    : this(status: ReceiptAnalysisStatus.succeeded, rawResponse: rawResponse);

  const ReceiptAnalysisResult.failed({String? errorCode})
    : this(status: ReceiptAnalysisStatus.failed, errorCode: errorCode);

  final ReceiptAnalysisStatus status;
  final String? rawResponse;
  final String? errorCode;

  bool get isSuccess => status == ReceiptAnalysisStatus.succeeded;
}
