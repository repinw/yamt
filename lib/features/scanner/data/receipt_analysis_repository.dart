import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/debug/debug_log.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_clients.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_parser.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository_helpers.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

part 'receipt_analysis_repository.g.dart';

const String _repositoryLogName = 'DeviceReceiptAnalysisRepository';
const String _receiptTemplateId = 'testtemplate';

abstract final class _ReceiptAnalysisRepositoryFailures {
  static const emptyResponse = ReceiptAnalysisResult.failed(
    errorCode: ReceiptAnalysisErrorCodes.emptyResponse,
  );
  static const aiRequest = ReceiptAnalysisResult.failed(
    errorCode: ReceiptAnalysisErrorCodes.aiRequestFailed,
  );
  static const parse = ReceiptAnalysisResult.failed(
    errorCode: ReceiptAnalysisErrorCodes.parseFailed,
  );
  static const unexpected = ReceiptAnalysisResult.failed(
    errorCode: ReceiptAnalysisErrorCodes.unexpected,
  );
}

/// Receipt analysis repository.
@riverpod
ReceiptAnalysisRepository receiptAnalysisRepository(Ref ref) {
  return DeviceReceiptAnalysisRepository(
    templateModelClient: ref.watch(receiptTemplateModelClientProvider),
    parser: ref.watch(receiptAnalysisParserProvider),
  );
}

/// Defines device receipt analysis repository.
class DeviceReceiptAnalysisRepository implements ReceiptAnalysisRepository {
  /// Creates an instance.
  DeviceReceiptAnalysisRepository({
    required ReceiptTemplateModelClient templateModelClient,
    required ReceiptAnalysisParser parser,
  }) : _templateModelClient = templateModelClient,
       _parser = parser;

  final ReceiptTemplateModelClient _templateModelClient;
  final ReceiptAnalysisParser _parser;

  @override
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  ) async {
    return _generateWithTemplate(
      templateId: _receiptTemplateId,
      selection: selection,
    );
  }

  Future<ReceiptAnalysisResult> _generateWithTemplate({
    required String templateId,
    required ReceiptInputSelection selection,
  }) async {
    Stopwatch? totalStopwatch;
    assert(() {
      totalStopwatch = startDebugStopwatch();
      return true;
    }(), 'Start debug receipt analysis total timing.');
    try {
      Stopwatch? inputStopwatch;
      assert(() {
        inputStopwatch = startDebugStopwatch();
        return true;
      }(), 'Start debug receipt analysis input timing.');
      final resolvedInputs = await _buildTemplateInputs(selection);
      assert(() {
        _logReceiptAnalysisTiming(
          'input',
          stopDebugStopwatch(inputStopwatch),
          selection: selection,
        );
        return true;
      }(), 'Log debug receipt analysis input timing.');

      Stopwatch? requestStopwatch;
      assert(() {
        requestStopwatch = startDebugStopwatch();
        return true;
      }(), 'Start debug receipt analysis request timing.');
      final responseText = await _templateModelClient.generateContent(
        templateId: templateId,
        inputs: resolvedInputs,
      );
      assert(() {
        _logReceiptAnalysisTiming(
          'model',
          stopDebugStopwatch(requestStopwatch),
          selection: selection,
        );
        return true;
      }(), 'Log debug receipt analysis request timing.');

      final normalizedResponse = _normalizeReceiptAnalysisResponse(
        responseText,
      );
      if (normalizedResponse == null) {
        return _ReceiptAnalysisRepositoryFailures.emptyResponse;
      }

      assert(() {
        _logReceiptAnalysisRawResponse(normalizedResponse);
        return true;
      }(), 'Log debug receipt analysis raw response.');
      Stopwatch? parseStopwatch;
      assert(() {
        parseStopwatch = startDebugStopwatch();
        return true;
      }(), 'Start debug receipt analysis parse timing.');
      final extraction = _parse(normalizedResponse);
      assert(() {
        _logReceiptAnalysisTiming(
          'parse',
          stopDebugStopwatch(parseStopwatch),
          selection: selection,
        );
        _logReceiptAnalysisTiming(
          'total',
          stopDebugStopwatch(totalStopwatch),
          selection: selection,
          itemCount: extraction.items.length,
        );
        return true;
      }(), 'Log debug receipt analysis parse and total timing.');
      return ReceiptAnalysisResult.succeeded(
        rawResponse: normalizedResponse,
        extraction: extraction,
      );
    } on _ReceiptParseException {
      return _ReceiptAnalysisRepositoryFailures.parse;
    } on _ReceiptInputPreparationException {
      return _ReceiptAnalysisRepositoryFailures.unexpected;
    } on Object catch (error, stackTrace) {
      _logReceiptAnalysisRepositoryError(
        message: 'Receipt AI request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return _ReceiptAnalysisRepositoryFailures.aiRequest;
    }
  }

  Future<Map<String, Object?>> _buildTemplateInputs(
    ReceiptInputSelection selection,
  ) async {
    try {
      return await buildReceiptTemplateInputs(selection);
    } on Object catch (error, stackTrace) {
      _logReceiptAnalysisRepositoryError(
        message: 'Receipt input preparation failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const _ReceiptInputPreparationException();
    }
  }

  ReceiptAnalysisExtraction _parse(String normalizedResponse) {
    try {
      return _parser.parse(normalizedResponse);
    } on Object catch (error, stackTrace) {
      _logReceiptAnalysisRepositoryError(
        message: 'Receipt analysis parse failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw _ReceiptParseException();
    }
  }
}

final class _ReceiptParseException implements Exception {}

final class _ReceiptInputPreparationException implements Exception {
  const _ReceiptInputPreparationException();
}

String? _normalizeReceiptAnalysisResponse(String? responseText) {
  if (responseText == null || responseText.trim().isEmpty) {
    return null;
  }

  return responseText;
}

void _logReceiptAnalysisRawResponse(String rawResponse) {
  debugLog('Receipt AI raw response:\n$rawResponse', name: _repositoryLogName);
}

void _logReceiptAnalysisTiming(
  String stage,
  Duration elapsed, {
  required ReceiptInputSelection selection,
  int? itemCount,
}) {
  final itemSuffix = itemCount == null ? '' : ', items: $itemCount';
  debugLog(
    'Receipt analysis $stage took ${elapsed.inMilliseconds}ms '
    'for ${selection.name}$itemSuffix.',
    name: _repositoryLogName,
  );
}

void _logReceiptAnalysisRepositoryError({
  required String message,
  required Object error,
  required StackTrace stackTrace,
}) {
  appLog(
    message,
    name: _repositoryLogName,
    error: error,
    stackTrace: stackTrace,
  );
}
